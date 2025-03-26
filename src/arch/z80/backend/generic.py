# ----------------------------------------------------------
# Generic instructions
# ----------------------------------------------------------

import re

from src.api.config import OPTIONS
from src.api.fp import immediate_float
from src.api.tmp_labels import tmp_label

from . import common, exception
from ._8bit import Bits8
from ._16bit import Bits16
from ._32bit import Bits32
from ._f16 import Fixed16
from ._float import Float
from .common import (
    ASMS,
    AT_END,
    CALL_BACK,
    END_LABEL,
    RE_HEXA,
    YY_TYPES,
    get_bytes_size,
    new_ASMID,
    runtime_call,
    to_byte,
    to_fixed,
    to_float,
    to_long,
    to_word,
)
from .exception import InvalidICError as InvalidIC
from .icinstruction import ICInstruction
from .quad import Quad
from .runtime import Labels as RuntimeLabel

# Label RegExp
RE_LABEL = re.compile(r"^[ \t]*[a-zA-Z_][_a-zA-Z\d]*:")


def _nop(ins: Quad):
    """Returns nothing. (Ignored nop)"""
    return []


def _org(ins: Quad):
    """Outputs an origin of code."""
    return ["org %s" % str(ins[1])]


def _exchg(ins: Quad):
    """Exchange ALL registers. If the processor
    does not support this, it must be implemented saving registers in a memory
    location.
    """
    output = ["ex af, af'", "exx"]
    return output


def _end(ins: Quad):
    """Outputs the ending sequence"""
    output = Bits16.get_oper(ins[1])
    output.append("ld b, h")
    output.append("ld c, l")

    if common.FLAG_end_emitted:
        return output + ["jp %s" % END_LABEL]

    common.FLAG_end_emitted = True

    output.append("%s:" % END_LABEL)
    if OPTIONS.headerless:
        return output + ["ret"]

    output.append("di")
    output.append("ld hl, (%s)" % CALL_BACK)
    output.append("ld sp, hl")
    output.append("exx")
    output.append("pop hl")
    output.append("exx")
    output.append("pop iy")
    output.append("pop ix")
    output.append("ei")
    output.append("ret")
    return output


def _label(ins: Quad):
    """Defines a Label."""
    return ["%s:" % str(ins[1])]


def _deflabel(ins: Quad):
    """Defines a Label with a value."""
    return ["%s EQU %s" % (str(ins[1]), str(ins[2]))]


def _data(ins: Quad):
    """Defines a data item (binary).
    It's just a constant expression to be converted do binary data "as is"

    1st parameter is the type-size (u8 or i8 for byte, u16 or i16 for word, etc)
    2nd parameter is the list of expressions. All of them will be converted to the
        type required.
    """
    output = []
    t = ins[1]
    q = eval(ins[2])

    if t in ("i8", "u8"):
        size = "B"
    elif t in ("i16", "u16"):
        size = "W"
    elif t in ("i32", "u32"):
        size = "W"
        z = []
        for expr in ins[2]:
            z.extend(["(%s) & 0xFFFF" % expr, "(%s) >> 16" % expr])
        q = z
    elif t == "str":
        size = "B"
        q = ['"%s"' % x.replace('"', '""') for x in q]
    elif t == "f":
        dat_ = [immediate_float(float(x)) for x in q]
        for x in dat_:
            output.extend(["DEFB %s" % x[0], "DEFW %s, %s" % (x[1], x[2])])
        return output
    else:
        raise InvalidIC(ins, "Unimplemented data size %s for %s" % (t, q))

    for x in q:
        output.append("DEF%s %s" % (size, x))

    return output


def _var(ins: Quad):
    """Defines a memory variable."""
    output = []
    output.append("%s:" % ins[1])
    output.append("DEFB %s" % ((int(ins[2]) - 1) * "00, " + "00"))

    return output


def _varx(ins: Quad):
    """Defines a memory space with a default CONSTANT expression
    1st parameter is the var name
    2nd parameter is the type-size (u8 or i8 for byte, u16 or i16 for word, etc)
    3rd parameter is the list of expressions. All of them will be converted to the
        type required.
    """
    output = []
    output.append("%s:" % ins[1])
    q = eval(ins[3])

    if ins[2] in ("i8", "u8"):
        size = "B"
    elif ins[2] in ("i16", "u16"):
        size = "W"
    elif ins[2] in ("i32", "u32"):
        size = "W"
        z = []
        for expr in q:
            z.extend(["(%s) & 0xFFFF" % expr, "(%s) >> 16" % expr])
        q = z
    else:
        raise InvalidIC(ins, "Unimplemented vard size: %s" % ins[2])

    for x in q:
        output.append("DEF%s %s" % (size, x))

    return output


def _vard(ins: Quad):
    """Defines a memory space with a default set of bytes/words in hexadecimal
    (starting with a hex number) or literals (starting with #).
    Numeric values with more than 2 digits represents a WORD (2 bytes) value.
    E.g. '01' => 01h, '001' => 1, 0 bytes (0001h)
    Literal values starts with # (1 byte) or ## (2 bytes)
    E.g. '#label + 1' => (label + 1) & 0xFF
         '##(label + 1)' => (label + 1) & 0xFFFF
    """
    output = []
    output.append("%s:" % ins[1])

    q = eval(ins[2])

    for x in q:
        if x[0] == "#":  # literal?
            size_t = "W" if x[1] == "#" else "B"
            output.append("DEF{0} {1}".format(size_t, x.lstrip("#")))
            continue

        # must be an hex number
        x = x.upper()
        assert RE_HEXA.match(x), 'expected an hex number, got "%s"' % x
        size_t = "B" if len(x) <= 2 else "W"
        if x[0] > "9":  # Not a number?
            x = "0" + x
        output.append(f"DEF{size_t} {x}h")

    return output


def _lvarx(ins: Quad) -> list[str]:
    """Defines a local variable. 1st param is offset of the local variable.
    2nd param is the type a list of bytes in hexadecimal.
    """
    output: list[str] = []

    l = eval(ins[3])  # List of bytes to push
    label = tmp_label()
    offset = int(ins[1])
    tmp = list(ins)
    tmp[1] = label
    ins = tmp
    AT_END.extend(_varx(ins))

    output.append(f"push {common.IDX_REG}")
    output.append("pop hl")
    output.append("ld bc, %i" % -offset)
    output.append("add hl, bc")
    output.append("ex de, hl")
    output.append("ld hl, %s" % label)
    output.append("ld bc, %i" % (len(l) * YY_TYPES[ins[2]]))
    output.append("ldir")

    return output


def _lvard(ins: Quad):
    """Defines a local variable. 1st param is offset of the local variable.
    2nd param is a list of bytes in hexadecimal.
    """
    output = []

    label = tmp_label()
    offset = int(ins[1])
    AT_END.extend(_vard(Quad(ICInstruction.VARD, label, ins[2])))

    output.append(f"push {common.IDX_REG}")
    output.append("pop hl")
    output.append("ld bc, %i" % -offset)
    output.append("add hl, bc")
    output.append("ex de, hl")
    output.append("ld hl, %s" % label)
    output.append("ld bc, %i" % get_bytes_size(eval(ins[2])))
    output.append("ldir")

    return output


def _larrd(ins: Quad):
    """Defines a local array.
    - 1st param is offset of the local variable.
    - 2nd param is a list of bytes in hexadecimal corresponding to the index table
    - 3rd param is the size of elements in byte
    - 4th param is a list (might be empty) of byte to initialize the array with
    - 5th param is a list (might be empty or 2 elements) of [lbound, ubound] labels.
    """
    output = []

    label = tmp_label()
    offset = int(ins[1])
    elements_size = ins[3]
    AT_END.extend(_vard(Quad(ICInstruction.VARD, label, ins[2])))

    bounds = eval(ins[5])
    if not isinstance(bounds, list) or len(bounds) not in (0, 2):
        raise InvalidIC(ins, "Bounds list length must be 0 or 2, not %s" % ins[5])

    have_bounds = bounds and any(x != "0" for x in bounds)
    if have_bounds:
        output.extend(
            [
                "ld hl, %s" % bounds[1],  # UBOUND Table PTR
                "push hl",
                "ld hl, %s" % bounds[0],  # LBOUND Table PTR
                "push hl",
            ]
        )

    must_initialize = ins[4] != "[]"
    if must_initialize:
        label2 = tmp_label()
        AT_END.extend(_vard(Quad(ICInstruction.VARD, label2, ins[4])))
        output.extend(["ld hl, %s" % label2, "push hl"])

    output.extend(
        [
            "ld hl, %i" % -offset,
            "ld de, %s" % label,
            "ld bc, %s" % elements_size,
        ]
    )

    if must_initialize:
        if not have_bounds:
            output.append(runtime_call(RuntimeLabel.ALLOC_INITIALIZED_LOCAL_ARRAY))
        else:
            output.append(runtime_call(RuntimeLabel.ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS))
    else:
        if not have_bounds:
            output.append(runtime_call(RuntimeLabel.ALLOC_LOCAL_ARRAY))
        else:
            output.append(runtime_call(RuntimeLabel.ALLOC_LOCAL_ARRAY_WITH_BOUNDS))

    return output


def _out(ins: Quad):
    """Translates OUT to asm."""
    output = Bits8.get_oper(ins[2])
    output.extend(Bits16.get_oper(ins[1]))
    output.append("ld b, h")
    output.append("ld c, l")
    output.append("out (c), a")

    return output


def _in(ins: Quad):
    """Translates IN to asm."""
    output = Bits16.get_oper(ins[1])
    output.append("ld b, h")
    output.append("ld c, l")
    output.append("in a, (c)")
    output.append("push af")

    return output


def _cast(ins: Quad):
    """Convert data from typeA to typeB (only numeric data types)"""
    # Signed and unsigned types are the same in the Z80
    tA = ins[2]  # From TypeA
    tB = ins[3]  # To TypeB

    xsB = sB = YY_TYPES[tB]  # Type sizes

    if tA in ("u8", "i8") and tB == "bool":
        return []  # bytes are booleans already (0 = False, not 0 = True)

    output = []
    if tA in ("u8", "i8", "bool"):
        output.extend(Bits8.get_oper(ins[4]))
    elif tA in ("u16", "i16"):
        output.extend(Bits16.get_oper(ins[4]))
    elif tA in ("u32", "i32"):
        output.extend(Bits32.get_oper(ins[4]))
    elif tA == "f16":
        output.extend(Fixed16.get_oper(ins[4]))
    elif tA == "f":
        output.extend(Float.get_oper(ins[4]))
    else:
        raise exception.GenericError("Internal error: invalid typecast from %s to %s" % (tA, tB))

    if tB in ("u8", "i8"):  # It was a byte
        output.extend(to_byte(tA))
    elif tB in ("u16", "i16"):
        output.extend(to_word(tA))
    elif tB in ("u32", "i32"):
        output.extend(to_long(tA))
    elif tB == "f16":
        output.extend(to_fixed(tA))
    elif tB == "f":
        output.extend(to_float(tA))
    else:
        raise exception.GenericError("Internal error: invalid typecast from %s to %s" % (tA, tB))

    xsB += sB % 2  # make it even (round up)

    if xsB > 4:
        output.extend(Float.fpush())
    else:
        if xsB > 2:
            output.append("push de")  # Fixed or 32 bit Integer

        if sB > 1:
            output.append("push hl")  # 16 bit Integer
        else:
            output.append("push af")  # 8 bit Integer

    return output


# ------------------- FLOW CONTROL instructions -------------------


def _jump(ins: Quad):
    """Jump to a label"""
    return ["jp %s" % str(ins[1])]


def _ret(ins: Quad):
    """Returns from a procedure / function"""
    return ["jp %s" % str(ins[1])]


def _call(ins: Quad):
    """Calls a function XXXX (or address XXXX)
    2nd parameter contains size of the returning result if any, and will be
    pushed onto the stack.
    """
    output = []
    output.append("call %s" % str(ins[1]))

    try:
        val = int(ins[2])
        if val == 1:
            output.append("push af")  # Byte
        else:
            if val > 4:
                output.extend(Float.fpush())
            else:
                if val > 2:
                    output.append("push de")
                if val > 1:
                    output.append("push hl")

    except ValueError:
        pass

    return output


def _enter(ins: Quad):
    """Enter function sequence for doing a function start
    ins[1] contains size (in bytes) of local variables
    Use '__fastcall__' as 1st parameter to prepare a fastcall
    function (no local variables).
    """
    output = []

    if ins[1] == "__fastcall__":
        return output

    output.append(f"push {common.IDX_REG}")
    output.append(f"ld {common.IDX_REG}, 0")
    output.append(f"add {common.IDX_REG}, sp")

    size_bytes = int(ins[1])

    if size_bytes != 0:
        if size_bytes < 7:
            output.append("ld hl, 0")
            output.extend(["push hl"] * (size_bytes >> 1))

            if size_bytes % 2:  # odd?
                output.append("push hl")
                output.append("inc sp")
        else:
            output.append("ld hl, -%i" % size_bytes)  # "Pushes nn bytes"
            output.append("add hl, sp")
            output.append("ld sp, hl")
            output.append("ld (hl), 0")
            output.append("ld bc, %i" % (size_bytes - 1))
            output.append("ld d, h")
            output.append("ld e, l")
            output.append("inc de")
            output.append("ldir")  # Clear with ZEROs

    return output


def _leave(ins: Quad):
    """Return from a function popping N bytes from the stack
    Use '__fastcall__' as 1st parameter, to just return
    """
    global FLAG_use_function_exit

    output = []

    if ins[1] == "__fastcall__":
        output.append("ret")
        return output

    nbytes = int(ins[1])  # Number of bytes to pop (params size)

    if nbytes == 0:
        output.append(f"ld sp, {common.IDX_REG}")
        output.append(f"pop {common.IDX_REG}")
        output.append("ret")

        return output

    if nbytes == 1:
        output.append(f"ld sp, {common.IDX_REG}")
        output.append(f"pop {common.IDX_REG}")
        output.append("inc sp")  # "Pops" 1 byte
        output.append("ret")

        return output

    if nbytes <= 11:  # Number of bytes it worth the hassle to "pop" off the stack
        output.append(f"ld sp, {common.IDX_REG}")
        output.append(f"pop {common.IDX_REG}")
        output.append("exx")
        output.append("pop hl")
        for i in range((nbytes >> 1) - 1):
            output.append("pop bc")  # Removes (n * 2  - 2) bytes form the stack

        if nbytes & 1:  # Odd?
            output.append("inc sp")  # "Pops" 1 byte (This should never happens, since params are always even-sized)

        output.append("ex (sp), hl")  # Place back return address
        output.append("exx")
        output.append("ret")

        return output

    if not common.FLAG_use_function_exit:
        common.FLAG_use_function_exit = True  # Use standard exit
        output.append("exx")
        output.append("ld hl, %i" % nbytes)
        output.append("__EXIT_FUNCTION:")
        output.append(f"ld sp, {common.IDX_REG}")
        output.append(f"pop {common.IDX_REG}")
        output.append("pop de")
        output.append("add hl, sp")
        output.append("ld sp, hl")
        output.append("push de")
        output.append("exx")
        output.append("ret")
    else:
        output.append("exx")
        output.append("ld hl, %i" % nbytes)
        output.append("jp __EXIT_FUNCTION")

    return output


def _memcopy(ins: Quad):
    """Copies a block of memory from param 2 addr
    to param 1 addr.
    """
    output = Bits16.get_oper(ins[3])
    output.append("ld b, h")
    output.append("ld c, l")
    output.extend(Bits16.get_oper(ins[1], ins[2], reversed=True))
    output.append("ldir")  # ***

    return output


def _inline(ins: Quad):
    """Inline code"""
    tmp = [x.strip(" \t\r") for x in ins[1].split("\n")]  # Split lines

    i = 0
    while i < len(tmp):
        if not tmp[i] or tmp[i][0] == ";":  # a comment
            i += 1
            continue

        if tmp[i][0] == "#":  # A preprocessor directive
            i += 1
            continue

        match = RE_LABEL.match(tmp[i])
        if not match:
            tmp[i] = "\t" + tmp[i]
            i += 1
            continue

        # It starts with a label. Do not tabulate
        i += 1

    output = []
    if not tmp:
        return output

    ASMLABEL = new_ASMID()
    ASMS[ASMLABEL] = tmp
    output.append(ASMLABEL)

    return output
