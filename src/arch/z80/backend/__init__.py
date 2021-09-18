#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et

import re
import src.api.fp

from collections import defaultdict

from typing import Dict, List, Set

from src.api import global_
from src.arch.z80.backend import errors
from src.api.config import OPTIONS, Action

from src.arch.z80.backend.errors import InvalidICError as InvalidIC
from src.arch.z80.backend.runtime.namespace import NAMESPACE
from src.arch.z80.optimizer.helpers import HI16, LO16
from src.arch.z80.optimizer.asm import Asm
from src.arch.z80.peephole import engine
from src.arch.z80.backend.runtime import Labels as RuntimeLabel

from .__common import runtime_call, is_int_type

# 8 bit arithmetic functions
from .__8bit import _add8, _sub8, _mul8, _divu8, _divi8, _modu8, _modi8, _neg8, _abs8

# 8 bit parameters and function call instrs
from .__8bit import _load8, _store8, _jzero8, _jnzero8, _jgezerou8, _jgezeroi8, _ret8, _param8, _fparam8

# 8 bit comparison functions
from .__8bit import _eq8, _lti8, _ltu8, _gti8, _gtu8, _ne8, _leu8, _lei8, _geu8, _gei8

# 8 bit boolean functions
from .__8bit import _or8, _and8, _not8, _xor8, _8bit_oper

# 8 bit shift operations
from .__8bit import _shru8, _shri8, _shl8

# 8 bit bitwise operations
from .__8bit import _bor8, _band8, _bnot8, _bxor8

# 16 bit arithmetic functions
from .__16bit import _add16, _sub16, _mul16, _divu16, _divi16, _modu16, _modi16, _neg16, _abs16, _jnzero16

# 16bit parameters and function call instrs
from .__16bit import _load16, _store16, _jzero16, _jgezerou16, _jgezeroi16, _ret16, _param16, _fparam16

# 16 bit comparison functions
from .__16bit import _eq16, _lti16, _ltu16, _gti16, _gtu16, _ne16, _leu16, _lei16, _geu16, _gei16

# 16 bit boolean functions
from .__16bit import _or16, _and16, _not16, _xor16, _16bit_oper

# 16 bit shift operations
from .__16bit import _shru16, _shri16, _shl16

# 16 bit bitwise operations
from .__16bit import _band16, _bor16, _bxor16, _bnot16

# 32 bit arithmetic functions
from .__32bit import _add32, _sub32, _mul32, _divu32, _divi32, _modu32, _modi32, _neg32, _abs32, _jnzero32

# 32 bit parameters and function call instrs
from .__32bit import _load32, _store32, _jzero32, _jgezerou32, _jgezeroi32, _ret32, _param32, _fparam32

# 32 bit comparison functions
from .__32bit import _eq32, _lti32, _ltu32, _gti32, _gtu32, _ne32, _leu32, _lei32, _geu32, _gei32

# 32 bit boolean functions
from .__32bit import _or32, _and32, _not32, _xor32, _32bit_oper

# 32 bit shift operations
from .__32bit import _shru32, _shri32, _shl32

# 32 bit bitwise operations
from .__32bit import _band32, _bor32, _bxor32, _bnot32

# Fixed Point arithmetic functions
from .__f16 import _addf16, _subf16, _mulf16, _divf16, _modf16, _negf16, _absf16

# f16 parameters and function call instrs
from .__f16 import _loadf16, _storef16, _jzerof16, _jnzerof16, _jgezerof16, _retf16, _paramf16, _fparamf16

# Fixed Point comparison functions
from .__f16 import _eqf16, _ltf16, _gtf16, _nef16, _lef16, _gef16

# Fixed Point boolean functions
from .__f16 import _orf16, _andf16, _notf16, _xorf16, _f16_oper

from .__f16 import f16  # Returns DE,HL of a decimal value

# Floating Point arithmetic functions
from .__float import _addf, _subf, _mulf, _divf, _modf, _negf, _powf, _absf

# Floating Point parameters and function call instrs
from .__float import _loadf, _storef, _jzerof, _jnzerof, _jgezerof, _retf, _paramf, _fparamf

# Floating Point comparison functions
from .__float import _eqf, _ltf, _gtf, _nef, _lef, _gef

# Floating Point boolean functions
from .__float import _orf, _andf, _notf, _xorf, _float_oper, _fpush, _fpop

# String arithmetic functions
from .__str import _addstr

# String comparison functions
from .__str import _ltstr, _gtstr, _eqstr, _lestr, _gestr, _nestr, _str_oper, _lenstr

# Param load and store instructions
from .__pload import _pload8, _pload16, _pload32, _ploadf, _ploadstr, _fploadstr
from .__pload import _pstore8, _pstore16, _pstore32, _pstoref16, _pstoref, _pstorestr
from .__pload import _paddr

from . import __common
from .__common import MEMORY, LABEL_COUNTER, TMP_LABELS, TMP_COUNTER, TMP_STORAGES, REQUIRES, INITS
from .__common import is_int, is_float, tmp_label

# Array store and load instructions
from .__array import _aload8, _aload16, _aload32, _aloadf, _aloadstr
from .__array import _astore8, _astore16, _astore32, _astoref16, _astoref, _astorestr
from .__array import _aaddr

# Array store and load instructions
from .__parray import _paload8, _paload16, _paload32, _paloadf, _paloadstr
from .__parray import _pastore8, _pastore16, _pastore32, _pastoref16, _pastoref, _pastorestr
from .__parray import _paaddr

__all__ = [
    "_fpop",
    "LABEL_COUNTER",
    "MEMORY",
    "TMP_COUNTER",
    "TMP_STORAGES",
    "HI16",
    "LO16",
]

# Label RegExp
RE_LABEL = re.compile(r"^[ \t]*[a-zA-Z_][_a-zA-Z\d]*:")

# (ix +/- ...) regexp
RE_IX_IDX = re.compile(r"^\([ \t]*ix[ \t]*[-+][ \t]*.+\)$")

# Label for the program START end EXIT
START_LABEL = f"{NAMESPACE}.__START_PROGRAM"
END_LABEL = f"{NAMESPACE}.__END_PROGRAM"
CALL_BACK = f"{NAMESPACE}.__CALL_BACK__"
MAIN_LABEL = f"{NAMESPACE}.__MAIN_PROGRAM__"
DATA_LABEL = global_.ZXBASIC_USER_DATA
DATA_END_LABEL = f"{DATA_LABEL}_END"

# Whether to use the FunctionExit scheme
FLAG_use_function_exit = False

# Whether an 'end' has already been emitted
FLAG_end_emitted = False

# Default code ORG
OPTIONS(Action.ADD_IF_NOT_DEFINED, name="org", type=int, default=32768)

# Default HEAP SIZE (Dynamic memory) in bytes
OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size", type=int, default=4768)  # A bit more than 4K

# List of modules (in alphabetical order) that, if included, should call MEM_INIT
MEMINITS = {
    "alloc.asm",
    "loadstr.asm",
    "storestr2.asm",
    "storestr.asm",
    "strcat.asm",
    "strcpy.asm",
    "string.asm",
    "strslice.asm",
}

# Internal data types definition, with its size in bytes, or -1 if it is variable (string)
# Compound types are only arrays, and have the t
YY_TYPES = {
    "u8": 1,  # 8 bit unsigned integer
    "u16": 2,  # 16 bit unsigned integer
    "u32": 4,  # 32 bit unsigned integer
    "i8": 1,  # 8 bit SIGNED integer
    "i16": 2,  # 16 bit SIGNED integer
    "i32": 4,  # 32 bit SIGNED integer
    "f16": 4,  # -32768.9999 to 32767.9999 -aprox.- fixed point decimal (step = 1/2^16)
    "f": 5,  # Floating point
}

RE_BOOL = re.compile(r"^(eq|ne|lt|le|gt|ge|and|or|xor|not)(([ui](8|16|32))|(f16|f|str))$")
RE_HEXA = re.compile(r"^[0-9A-F]+$")


# This will be appended at the end  (useful for lvard, for example)
AT_END = []

# A table with ASM block entered by the USER (these won't be optimized)
ASMS = {}
ASMCOUNT = 0  # ASM blocks counter


def init():
    """Initializes this module"""
    global ASMS
    global ASMCOUNT
    global AT_END
    global FLAG_end_emitted
    global FLAG_use_function_exit

    __common.init()

    ASMS = {}
    ASMCOUNT = 0
    AT_END = []
    FLAG_use_function_exit = False
    FLAG_end_emitted = False

    # Default code ORG
    OPTIONS(Action.ADD, name="org", type=int, default=32768)
    # Default HEAP SIZE (Dynamic memory) in bytes
    OPTIONS(Action.ADD, name="heap_size", type=int, default=4768, ignore_none=True)  # A bit more than 4K
    # Labels for HEAP START (might not be used if not needed)
    OPTIONS(Action.ADD, name="heap_start_label", type=str, default=f"{NAMESPACE}.ZXBASIC_MEM_HEAP")
    # Labels for HEAP SIZE (might not be used if not needed)
    OPTIONS(Action.ADD, name="heap_size_label", type=str, default=f"{NAMESPACE}.ZXBASIC_HEAP_SIZE")
    # Flag for headerless mode (No prologue / epilogue)
    OPTIONS(Action.ADD, name="headerless", type=bool, default=False, ignore_none=True)

    engine.main()  # inits the optimizer


def new_ASMID():
    """Returns a new unique ASM block id"""
    global ASMCOUNT

    result = "##ASM%i" % ASMCOUNT
    ASMCOUNT += 1
    return result


def get_bytes(elements: List[str]) -> List[str]:
    """Returns a list a default set of bytes/words in hexadecimal
    (starting with an hex number) or literals (starting with #).
    Numeric values with more than 2 digits represents a WORD (2 bytes) value.
    E.g. '01' => 01h, '001' => 1, 0 bytes (0001h)
    Literal values starts with # (1 byte) or ## (2 bytes)
    E.g. '#label + 1' => (label + 1) & 0xFF
         '##(label + 1)' => (label + 1) & 0xFFFF
    """
    output = []

    for x in elements:
        if x.startswith("##"):  # 2-byte literal
            output.append("({}) & 0xFF".format(x[2:]))
            output.append("(({}) >> 8) & 0xFF".format(x[2:]))
            continue

        if x.startswith("#"):  # 1-byte literal
            output.append("({}) & 0xFF".format(x[1:]))
            continue

        # must be an hex number
        assert RE_HEXA.match(x), 'expected an hex number, got "%s"' % x
        output.append("%02X" % int(x[-2:], 16))
        if len(x) > 2:
            output.append("%02X" % int(x[-4:-2:], 16))

    return output


def get_bytes_size(elements: List[str]) -> int:
    """Defines a memory space with a default set of bytes/words in hexadecimal
    (starting with an hex number) or literals (starting with #).
    Numeric values with more than 2 digits represents a WORD (2 bytes) value.
    E.g. '01' => 01h, '001' => 1, 0 bytes (0001h)
    Literal values starts with # (1 byte) or ## (2 bytes)
    E.g. '#label + 1' => (label + 1) & 0xFF
         '##(label + 1)' => (label + 1) & 0xFFFF
    """
    return len(get_bytes(elements))


# ------------------------------------------------------------------
# Typecast conversions
# ------------------------------------------------------------------


def to_byte(stype):
    """Returns the instruction sequence for converting from
    the given type to byte.
    """
    output = []

    if stype in ("i8", "u8"):
        return []

    if is_int_type(stype):
        output.append("ld a, l")
    elif stype == "f16":
        output.append("ld a, e")
    elif stype == "f":  # Converts C ED LH to byte
        output.append(runtime_call(RuntimeLabel.FTOU32REG))
        output.append("ld a, l")

    return output


def to_word(stype):
    """Returns the instruction sequence for converting the given
    type stored in DE,HL to word (unsigned) HL.
    """
    output = []  # List of instructions

    if stype == "u8":  # Byte to word
        output.append("ld l, a")
        output.append("ld h, 0")

    elif stype == "i8":  # Signed byte to word
        output.append("ld l, a")
        output.append("add a, a")
        output.append("sbc a, a")
        output.append("ld h, a")

    elif stype == "f16":  # Must MOVE HL into DE
        output.append("ex de, hl")

    elif stype == "f":
        output.append(runtime_call(RuntimeLabel.FTOU32REG))

    return output


def to_long(stype):
    """Returns the instruction sequence for converting the given
    type stored in DE,HL to long (DE, HL).
    """
    output = []  # List of instructions

    if stype in ("i8", "u8", "f16"):  # Byte to word
        output = to_word(stype)

        if stype != "f16":  # If its a byte, just copy H to D,E
            output.append("ld e, h")
            output.append("ld d, h")

    if stype in ("i16", "f16"):  # Signed byte or fixed to word
        output.append("ld a, h")
        output.append("add a, a")
        output.append("sbc a, a")
        output.append("ld e, a")
        output.append("ld d, a")

    elif stype == "u16":
        output.append("ld de, 0")

    elif stype == "f":
        output.append(runtime_call(RuntimeLabel.FTOU32REG))

    return output


def to_fixed(stype):
    """Returns the instruction sequence for converting the given
    type stored in DE,HL to fixed DE,HL.
    """
    output = []  # List of instructions

    if is_int_type(stype):
        output = to_word(stype)
        output.append("ex de, hl")
        output.append("ld hl, 0")  # 'Truncate' the fixed point
    elif stype == "f":
        output.append(runtime_call(RuntimeLabel.FTOF16REG))

    return output


def to_float(stype: str) -> List[str]:
    """Returns the instruction sequence for converting the given
    type stored in DE,HL to fixed DE,HL.
    """
    output: List[str] = []  # List of instructions

    if stype == "f":
        return output  # Nothing to do

    if stype == "f16":
        output.append(runtime_call(RuntimeLabel.F16TOFREG))
        return output

    # If we reach this point, it's an integer type
    if stype == "u8":
        output.append(runtime_call(RuntimeLabel.U8TOFREG))
    elif stype == "i8":
        output.append(runtime_call(RuntimeLabel.I8TOFREG))
    else:
        output = to_long(stype)
        if stype in ("i16", "i32"):
            output.append(runtime_call(RuntimeLabel.I32TOFREG))
        else:
            output.append(runtime_call(RuntimeLabel.U32TOFREG))

    return output


# ------------------------------------------------------------------
# Lowlevel (to ASM) instructions implementation
# ------------------------------------------------------------------
def _nop(ins):
    """Returns nothing. (Ignored nop)"""
    return []


def _org(ins):
    """Outputs an origin of code."""
    return ["org %s" % str(ins.quad[1])]


def _exchg(ins):
    """Exchange ALL registers. If the processor
    does not support this, it must be implemented saving registers in a memory
    location.
    """
    output = ["ex af, af'", "exx"]
    return output


def _end(ins):
    """Outputs the ending sequence"""
    global FLAG_end_emitted
    output = _16bit_oper(ins.quad[1])
    output.append("ld b, h")
    output.append("ld c, l")

    if FLAG_end_emitted:
        return output + ["jp %s" % END_LABEL]

    FLAG_end_emitted = True

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


def _label(ins):
    """Defines a Label."""
    return ["%s:" % str(ins.quad[1])]


def _deflabel(ins):
    """Defines a Label with a value."""
    return ["%s EQU %s" % (str(ins.quad[1]), str(ins.quad[2]))]


def _data(ins):
    """Defines a data item (binary).
    It's just a constant expression to be converted do binary data "as is"

    1st parameter is the type-size (u8 or i8 for byte, u16 or i16 for word, etc)
    2nd parameter is the list of expressions. All of them will be converted to the
        type required.
    """
    output = []
    t = ins.quad[1]
    q = eval(ins.quad[2])

    if t in ("i8", "u8"):
        size = "B"
    elif t in ("i16", "u16"):
        size = "W"
    elif t in ("i32", "u32"):
        size = "W"
        z = list()
        for expr in ins.quad[2]:
            z.extend(["(%s) & 0xFFFF" % expr, "(%s) >> 16" % expr])
        q = z
    elif t == "str":
        size = "B"
        q = ['"%s"' % x.replace('"', '""') for x in q]
    elif t == "f":
        dat_ = [src.api.fp.immediate_float(float(x)) for x in q]
        for x in dat_:
            output.extend(["DEFB %s" % x[0], "DEFW %s, %s" % (x[1], x[2])])
        return output
    else:
        raise InvalidIC(ins.quad, "Unimplemented data size %s for %s" % (t, q))

    for x in q:
        output.append("DEF%s %s" % (size, x))

    return output


def _var(ins):
    """Defines a memory variable."""
    output = []
    output.append("%s:" % ins.quad[1])
    output.append("DEFB %s" % ((int(ins.quad[2]) - 1) * "00, " + "00"))

    return output


def _varx(ins):
    """Defines a memory space with a default CONSTANT expression
    1st parameter is the var name
    2nd parameter is the type-size (u8 or i8 for byte, u16 or i16 for word, etc)
    3rd parameter is the list of expressions. All of them will be converted to the
        type required.
    """
    output = []
    output.append("%s:" % ins.quad[1])
    q = eval(ins.quad[3])

    if ins.quad[2] in ("i8", "u8"):
        size = "B"
    elif ins.quad[2] in ("i16", "u16"):
        size = "W"
    elif ins.quad[2] in ("i32", "u32"):
        size = "W"
        z = list()
        for expr in q:
            z.extend(["(%s) & 0xFFFF" % expr, "(%s) >> 16" % expr])
        q = z
    else:
        raise InvalidIC(ins.quad, "Unimplemented vard size: %s" % ins.quad[2])

    for x in q:
        output.append("DEF%s %s" % (size, x))

    return output


def _vard(ins):
    """Defines a memory space with a default set of bytes/words in hexadecimal
    (starting with an hex number) or literals (starting with #).
    Numeric values with more than 2 digits represents a WORD (2 bytes) value.
    E.g. '01' => 01h, '001' => 1, 0 bytes (0001h)
    Literal values starts with # (1 byte) or ## (2 bytes)
    E.g. '#label + 1' => (label + 1) & 0xFF
         '##(label + 1)' => (label + 1) & 0xFFFF
    """
    output = []
    output.append("%s:" % ins.quad[1])

    q = eval(ins.quad[2])

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
        output.append("DEF{0} {1}h".format(size_t, x))

    return output


def _lvarx(ins):
    """Defines a local variable. 1st param is offset of the local variable.
    2nd param is the type a list of bytes in hexadecimal.
    """
    output = []

    l = eval(ins.quad[3])  # List of bytes to push
    label = tmp_label()
    offset = int(ins.quad[1])
    tmp = list(ins.quad)
    tmp[1] = label
    ins.quad = tmp
    AT_END.extend(_varx(ins))

    output.append("push ix")
    output.append("pop hl")
    output.append("ld bc, %i" % -offset)
    output.append("add hl, bc")
    output.append("ex de, hl")
    output.append("ld hl, %s" % label)
    output.append("ld bc, %i" % (len(l) * YY_TYPES[ins.quad[2]]))
    output.append("ldir")

    return output


def _lvard(ins):
    """Defines a local variable. 1st param is offset of the local variable.
    2nd param is a list of bytes in hexadecimal.
    """
    output = []

    label = tmp_label()
    offset = int(ins.quad[1])
    tmp = list(ins.quad)
    tmp[1] = label
    ins.quad = tmp
    AT_END.extend(_vard(ins))

    output.append("push ix")
    output.append("pop hl")
    output.append("ld bc, %i" % -offset)
    output.append("add hl, bc")
    output.append("ex de, hl")
    output.append("ld hl, %s" % label)
    output.append("ld bc, %i" % get_bytes_size(eval(tmp[2])))
    output.append("ldir")

    return output


def _larrd(ins):
    """Defines a local array.
    - 1st param is offset of the local variable.
    - 2nd param is a list of bytes in hexadecimal corresponding to the index table
    - 3rd param is the size of elements in byte
    - 4th param is a list (might be empty) of byte to initialize the array with
    - 5th param is a list (might be empty or 2 elements) of [lbound, ubound] labels.
    """
    output = []

    label = tmp_label()
    offset = int(ins.quad[1])
    elements_size = ins.quad[3]
    AT_END.extend(_vard(Quad("vard", label, ins.quad[2])))

    bounds = eval(ins.quad[5])
    if not isinstance(bounds, list) or len(bounds) not in (0, 2):
        raise InvalidIC(ins.quad, "Bounds list length must be 0 or 2, not %s" % ins.quad[5])

    if bounds:
        output.extend(
            [
                "ld hl, %s" % bounds[1],
                "push hl",
                "ld hl, %s" % bounds[0],
                "push hl",
            ]
        )

    must_initialize = ins.quad[4] != "[]"
    if must_initialize:
        label2 = tmp_label()
        AT_END.extend(_vard(Quad("vard", label2, ins.quad[4])))
        output.extend(["ld hl, %s" % label2, "push hl"])

    output.extend(
        [
            "ld hl, %i" % -offset,
            "ld de, %s" % label,
            "ld bc, %s" % elements_size,
        ]
    )

    if must_initialize:
        if not bounds:
            output.append(runtime_call(RuntimeLabel.ALLOC_INITIALIZED_LOCAL_ARRAY))
        else:
            output.append(runtime_call(RuntimeLabel.ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS))
    else:
        if not bounds:
            output.append(runtime_call(RuntimeLabel.ALLOC_LOCAL_ARRAY))
        else:
            output.append(runtime_call(RuntimeLabel.ALLOC_LOCAL_ARRAY_WITH_BOUNDS))

    return output


def _out(ins):
    """Translates OUT to asm."""
    output = _8bit_oper(ins.quad[2])
    output.extend(_16bit_oper(ins.quad[1]))
    output.append("ld b, h")
    output.append("ld c, l")
    output.append("out (c), a")

    return output


def _in(ins):
    """Translates IN to asm."""
    output = _16bit_oper(ins.quad[1])
    output.append("ld b, h")
    output.append("ld c, l")
    output.append("in a, (c)")
    output.append("push af")

    return output


def _loadstr(ins):
    """Loads a string value from a memory address."""
    temporal, output = _str_oper(ins.quad[2], no_exaf=True)

    if not temporal:
        output.append(runtime_call(RuntimeLabel.LOADSTR))

    output.append("push hl")
    return output


def _storestr(ins):
    """Stores a string value into a memory address.
    It copies content of 2nd operand (string), into 1st, reallocating
    dynamic memory for the 1st str. These instruction DOES ALLOW
    immediate strings for the 2nd parameter, starting with '#'.

    Must prepend '#' (immediate sigil) to 1st operand, as we need
    the & address of the destination.
    """
    op1 = ins.quad[1]
    indirect = op1[0] == "*"
    if indirect:
        op1 = op1[1:]

    immediate = op1[0] == "#"
    if immediate and not indirect:
        raise InvalidIC("storestr does not allow immediate destination", ins.quad)

    if not indirect:
        op1 = "#" + op1

    tmp1, tmp2, output = _str_oper(op1, ins.quad[2], no_exaf=True)

    if not tmp2:
        output.append(runtime_call(RuntimeLabel.STORE_STR))
    else:
        output.append(runtime_call(RuntimeLabel.STORE_STR2))

    return output


def _cast(ins):
    """Convert data from typeA to typeB (only numeric data types)"""
    # Signed and unsigned types are the same in the Z80
    tA = ins.quad[2]  # From TypeA
    tB = ins.quad[3]  # To TypeB

    xsB = sB = YY_TYPES[tB]  # Type sizes

    output = []
    if tA in ("u8", "i8"):
        output.extend(_8bit_oper(ins.quad[4]))
    elif tA in ("u16", "i16"):
        output.extend(_16bit_oper(ins.quad[4]))
    elif tA in ("u32", "i32"):
        output.extend(_32bit_oper(ins.quad[4]))
    elif tA == "f16":
        output.extend(_f16_oper(ins.quad[4]))
    elif tA == "f":
        output.extend(_float_oper(ins.quad[4]))
    else:
        raise errors.GenericError("Internal error: invalid typecast from %s to %s" % (tA, tB))

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

    xsB += sB % 2  # make it even (round up)

    if xsB > 4:
        output.extend(_fpush())
    else:
        if xsB > 2:
            output.append("push de")  # Fixed or 32 bit Integer

        if sB > 1:
            output.append("push hl")  # 16 bit Integer
        else:
            output.append("push af")  # 8 bit Integer

    return output


# ------------------- FLOW CONTROL instructions -------------------


def _jump(ins):
    """Jump to a label"""
    return ["jp %s" % str(ins.quad[1])]


def _jzerostr(ins):
    """Jumps if top of the stack contains a NULL pointer
    or its len is Zero
    """
    # TODO: Check if this is ever used?
    output = []
    disposable = False  # True if string must be freed from memory

    if ins.quad[1][0] == "_":  # Variable?
        output.append("ld hl, (%s)" % ins.quad[1][0])
    else:
        output.append("pop hl")
        output.append("push hl")  # Saves it for later
        disposable = True

    output.append(runtime_call(RuntimeLabel.STRLEN))

    if disposable:
        output.append("ex (sp), hl")
        output.append(runtime_call(RuntimeLabel.MEM_FREE))
        output.append("pop hl")

    output.append("ld a, h")
    output.append("or l")
    output.append("jp z, %s" % str(ins.quad[2]))
    return output


def _jnzerostr(ins):
    """Jumps if top of the stack contains a string with
    at less 1 char
    """
    # TODO: Check if this is ever used?
    output = []
    disposable = False  # True if string must be freed from memory

    if ins.quad[1][0] == "_":  # Variable?
        output.append("ld hl, (%s)" % ins.quad[1][0])
    else:
        output.append("pop hl")
        output.append("push hl")  # Saves it for later
        disposable = True

    output.append(runtime_call(RuntimeLabel.STRLEN))

    if disposable:
        output.append("ex (sp), hl")
        output.append(runtime_call(RuntimeLabel.MEM_FREE))
        output.append("pop hl")

    output.append("ld a, h")
    output.append("or l")
    output.append("jp nz, %s" % str(ins.quad[2]))
    return output


def _ret(ins):
    """Returns from a procedure / function"""
    return ["jp %s" % str(ins.quad[1])]


def _retstr(ins):
    """Returns from a procedure / function a string pointer (16bits) value"""
    tmp, output = _str_oper(ins.quad[1], no_exaf=True)

    if not tmp:
        output.append(runtime_call(RuntimeLabel.LOADSTR))

    output.append("#pragma opt require hl")
    output.append("jp %s" % str(ins.quad[2]))
    return output


def _call(ins):
    """Calls a function XXXX (or address XXXX)
    2nd parameter contains size of the returning result if any, and will be
    pushed onto the stack.
    """
    output = []
    output.append("call %s" % str(ins.quad[1]))

    try:
        val = int(ins.quad[2])
        if val == 1:
            output.append("push af")  # Byte
        else:
            if val > 4:
                output.extend(_fpush())
            else:
                if val > 2:
                    output.append("push de")
                if val > 1:
                    output.append("push hl")

    except ValueError:
        pass

    return output


def _leave(ins):
    """Return from a function popping N bytes from the stack
    Use '__fastcall__' as 1st parameter, to just return
    """
    global FLAG_use_function_exit

    output = []

    if ins.quad[1] == "__fastcall__":
        output.append("ret")
        return output

    nbytes = int(ins.quad[1])  # Number of bytes to pop (params size)

    if nbytes == 0:
        output.append("ld sp, ix")
        output.append("pop ix")
        output.append("ret")

        return output

    if nbytes == 1:
        output.append("ld sp, ix")
        output.append("pop ix")
        output.append("inc sp")  # "Pops" 1 byte
        output.append("ret")

        return output

    if nbytes <= 11:  # Number of bytes it worth the hassle to "pop" off the stack
        output.append("ld sp, ix")
        output.append("pop ix")
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

    if not FLAG_use_function_exit:
        FLAG_use_function_exit = True  # Use standard exit
        output.append("exx")
        output.append("ld hl, %i" % nbytes)
        output.append("__EXIT_FUNCTION:")
        output.append("ld sp, ix")
        output.append("pop ix")
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


def _enter(ins):
    """Enter function sequence for doing a function start
    ins.quad[1] contains size (in bytes) of local variables
    Use '__fastcall__' as 1st parameter to prepare a fastcall
    function (no local variables).
    """
    output = []

    if ins.quad[1] == "__fastcall__":
        return output

    output.append("push ix")
    output.append("ld ix, 0")
    output.append("add ix, sp")

    size_bytes = int(ins.quad[1])

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


def _paramstr(ins):
    """Pushes an 16 bit unsigned value, which points
    to a string. For indirect values, it will push
    the pointer to the pointer :-)
    """
    (tmp, output) = _str_oper(ins.quad[1])
    output.pop()  # Remove a register flag (useless here)
    tmp = ins.quad[1][0] in ("#", "_")  # Determine if the string must be duplicated

    if tmp:
        output.append(runtime_call(RuntimeLabel.LOADSTR))  # Must be duplicated

    output.append("push hl")
    return output


def _fparamstr(ins):
    """Passes a string ptr as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate) --prefixed with '#'--
    """
    (tmp1, output) = _str_oper(ins.quad[1])

    return output


def _memcopy(ins):
    """Copies a block of memory from param 2 addr
    to param 1 addr.
    """
    output = _16bit_oper(ins.quad[3])
    output.append("ld b, h")
    output.append("ld c, l")
    output.extend(_16bit_oper(ins.quad[1], ins.quad[2], reversed=True))
    output.append("ldir")  # ***

    return output


def _inline(ins):
    """Inline code"""
    tmp = [x.strip(" \t\r") for x in ins.quad[1].split("\n")]  # Split lines

    i = 0
    while i < len(tmp):
        if not tmp[i]:  # discard empty lines
            tmp.pop(i)
            continue

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


# -------- 3 address code implementation ----------
class Quad:
    """Implements a Quad code instruction."""

    def __init__(self, *args):
        """Creates a quad-uple checking it has the current params.
        Operators should be passed as Quad('+', tSymbol, val1, val2)
        """
        if not args:
            raise InvalidIC("<null>")

        if args[0] not in QUADS.keys():
            errors.throw_invalid_quad_code(args[0])

        if len(args) - 1 != QUADS[args[0]][0]:
            errors.throw_invalid_quad_params(args[0], len(args) - 1, QUADS[args[0]][0])

        args = tuple([str(x) for x in args])  # Convert it to strings

        self.quad = args
        self.op = args[0]

    def __str__(self):
        """String representation"""
        return str(self.quad)


# Table describing operations
# 'OPERATOR' -> [Number of arguments]
QUADS = {
    "addu8": [3, _add8],
    "addi8": [3, _add8],
    "addi16": [3, _add16],
    "addu16": [3, _add16],
    "addi32": [3, _add32],
    "addu32": [3, _add32],
    "addf16": [3, _addf16],
    "addf": [3, _addf],
    "addstr": [3, _addstr],
    "data": [2, _data],
    "subi8": [3, _sub8],
    "subu8": [3, _sub8],
    "subi16": [3, _sub16],
    "subu16": [3, _sub16],
    "subi32": [3, _sub32],
    "subu32": [3, _sub32],
    "subf16": [3, _subf16],
    "subf": [3, _subf],
    "muli8": [3, _mul8],
    "mulu8": [3, _mul8],
    "muli16": [3, _mul16],
    "mulu16": [3, _mul16],
    "muli32": [3, _mul32],
    "mulu32": [3, _mul32],
    "mulf16": [3, _mulf16],
    "mulf": [3, _mulf],
    "divu8": [3, _divu8],
    "divi8": [3, _divi8],
    "divu16": [3, _divu16],
    "divi16": [3, _divi16],
    "divu32": [3, _divu32],
    "divi32": [3, _divi32],
    "divf16": [3, _divf16],
    "divf": [3, _divf],
    "powf": [3, _powf],
    "modu8": [3, _modu8],
    "modi8": [3, _modi8],
    "modu16": [3, _modu16],
    "modi16": [3, _modi16],
    "modu32": [3, _modu32],
    "modi32": [3, _modi32],
    "modf16": [3, _modf16],
    "modf": [3, _modf],
    "shru8": [3, _shru8],
    "shri8": [3, _shri8],
    "shlu8": [3, _shl8],
    "shli8": [3, _shl8],
    "shru16": [3, _shru16],
    "shri16": [3, _shri16],
    "shlu16": [3, _shl16],
    "shli16": [3, _shl16],
    "shru32": [3, _shru32],
    "shri32": [3, _shri32],
    "shlu32": [3, _shl32],
    "shli32": [3, _shl32],
    "ltu8": [3, _ltu8],
    "lti8": [3, _lti8],
    "ltu16": [3, _ltu16],
    "lti16": [3, _lti16],
    "ltu32": [3, _ltu32],
    "lti32": [3, _lti32],
    "ltf16": [3, _ltf16],
    "ltf": [3, _ltf],
    "ltstr": [3, _ltstr],
    "gtu8": [3, _gtu8],
    "gti8": [3, _gti8],
    "gtu16": [3, _gtu16],
    "gti16": [3, _gti16],
    "gtu32": [3, _gtu32],
    "gti32": [3, _gti32],
    "gtf16": [3, _gtf16],
    "gtf": [3, _gtf],
    "gtstr": [3, _gtstr],
    "leu8": [3, _leu8],
    "lei8": [3, _lei8],
    "leu16": [3, _leu16],
    "lei16": [3, _lei16],
    "leu32": [3, _leu32],
    "lei32": [3, _lei32],
    "lef16": [3, _lef16],
    "lef": [3, _lef],
    "lestr": [3, _lestr],
    "geu8": [3, _geu8],
    "gei8": [3, _gei8],
    "geu16": [3, _geu16],
    "gei16": [3, _gei16],
    "geu32": [3, _geu32],
    "gei32": [3, _gei32],
    "gef16": [3, _gef16],
    "gef": [3, _gef],
    "gestr": [3, _gestr],
    "equ8": [3, _eq8],
    "eqi8": [3, _eq8],
    "equ16": [3, _eq16],
    "eqi16": [3, _eq16],
    "equ32": [3, _eq32],
    "eqi32": [3, _eq32],
    "eqf16": [3, _eqf16],
    "eqf": [3, _eqf],
    "eqstr": [3, _eqstr],
    "neu8": [3, _ne8],
    "nei8": [3, _ne8],
    "neu16": [3, _ne16],
    "nei16": [3, _ne16],
    "neu32": [3, _ne32],
    "nei32": [3, _ne32],
    "nef16": [3, _nef16],
    "nef": [3, _nef],
    "nestr": [3, _nestr],
    "absi8": [2, _abs8],  # x = -x if x < 0
    "absi16": [2, _abs16],  # x = -x if x < 0
    "absi32": [2, _abs32],  # x = -x if x < 0
    "absf16": [2, _absf16],  # x = -x if x < 0
    "absf": [2, _absf],  # x = -x if x < 0
    "negu8": [2, _neg8],  # x = -y
    "negi8": [2, _neg8],  # x = -y
    "negu16": [2, _neg16],  # x = -y
    "negi16": [2, _neg16],  # x = -y
    "negu32": [2, _neg32],  # x = -y
    "negi32": [2, _neg32],  # x = -y
    "negf16": [2, _negf16],  # x = -y
    "negf": [2, _negf],  # x = -y
    "andu8": [3, _and8],  # x = A and B
    "andi8": [3, _and8],  # x = A and B
    "andu16": [3, _and16],  # x = A and B
    "andi16": [3, _and16],  # x = A and B
    "andu32": [3, _and32],  # x = A and B
    "andi32": [3, _and32],  # x = A and B
    "andf16": [3, _andf16],  # x = A and B
    "andf": [3, _andf],  # x = A and B
    "oru8": [3, _or8],  # x = A or B
    "ori8": [3, _or8],  # x = A or B
    "oru16": [3, _or16],  # x = A or B
    "ori16": [3, _or16],  # x = A or B
    "oru32": [3, _or32],  # x = A or B
    "ori32": [3, _or32],  # x = A or B
    "orf16": [3, _orf16],  # x = A or B
    "orf": [3, _orf],  # x = A or B
    "xoru8": [3, _xor8],  # x = A xor B
    "xori8": [3, _xor8],  # x = A xor B
    "xoru16": [3, _xor16],  # x = A xor B
    "xori16": [3, _xor16],  # x = A xor B
    "xoru32": [3, _xor32],  # x = A xor B
    "xori32": [3, _xor32],  # x = A xor B
    "xorf16": [3, _xorf16],  # x = A xor B
    "xorf": [3, _xorf],  # x = A xor B
    "notu8": [2, _not8],  # x = not B
    "noti8": [2, _not8],  # x = not B
    "notu16": [2, _not16],  # x = not B
    "noti16": [2, _not16],  # x = not B
    "notu32": [2, _not32],  # x = not B
    "noti32": [2, _not32],  # x = not B
    "notf16": [2, _notf16],  # x = not B
    "notf": [2, _notf],  # x = not B
    "jump": [1, _jump],  # jmp LABEL
    "lenstr": [2, _lenstr],  # Gets strlen
    "jzeroi8": [2, _jzero8],  # if X == 0 jmp LABEL
    "jzerou8": [2, _jzero8],  # if X == 0 jmp LABEL
    "jzeroi16": [2, _jzero16],  # if X == 0 jmp LABEL
    "jzerou16": [2, _jzero16],  # if X == 0 jmp LABEL
    "jzeroi32": [2, _jzero32],  # if X == 0 jmp LABEL (32bit, fixed)
    "jzerou32": [2, _jzero32],  # if X == 0 jmp LABEL (32bit, fixed)
    "jzerof16": [2, _jzerof16],  # if X == 0 jmp LABEL (32bit, fixed)
    "jzerof": [2, _jzerof],  # if X == 0 jmp LABEL (float)
    "jzerostr": [2, _jzerostr],  # if str is NULL or len(str) == 0, jmp LABEL
    "jnzeroi8": [2, _jnzero8],  # if X != 0 jmp LABEL
    "jnzerou8": [2, _jnzero8],  # if X != 0 jmp LABEL
    "jnzeroi16": [2, _jnzero16],  # if X != 0 jmp LABEL
    "jnzerou16": [2, _jnzero16],  # if X != 0 jmp LABEL
    "jnzeroi32": [2, _jnzero32],  # if X != 0 jmp LABEL (32bit, fixed)
    "jnzerou32": [2, _jnzero32],  # if X != 0 jmp LABEL (32bit, fixed)
    "jnzerof16": [2, _jnzerof16],  # if X != 0 jmp LABEL (32bit, fixed)
    "jnzerof": [2, _jnzerof],  # if X != 0 jmp LABEL (float)
    "jnzerostr": [2, _jnzerostr],  # if str is not NULL and len(str) > 0, jmp LABEL
    "jgezeroi8": [2, _jgezeroi8],  # if X >= 0 jmp LABEL
    "jgezerou8": [2, _jgezerou8],  # if X >= 0 jmp LABEL (ALWAYS TRUE)
    "jgezeroi16": [2, _jgezeroi16],  # if X >= 0 jmp LABEL
    "jgezerou16": [2, _jgezerou16],  # if X >= 0 jmp LABEL (ALWAYS TRUE)
    "jgezeroi32": [2, _jgezeroi32],  # if X >= 0 jmp LABEL (32bit, fixed)
    "jgezerou32": [2, _jgezerou32],  # if X >= 0 jmp LABEL (32bit, fixed) (always true)
    "jgezerof16": [2, _jgezerof16],  # if X >= 0 jmp LABEL (32bit, fixed)
    "jgezerof": [2, _jgezerof],  # if X >= 0 jmp LABEL (float)
    "paramu8": [1, _param8],  # Push 8 bit param onto the stack
    "parami8": [1, _param8],  # Push 8 bit param onto the stack
    "paramu16": [1, _param16],  # Push 16 bit param onto the stack
    "parami16": [1, _param16],  # Push 16 bit param onto the stack
    "paramu32": [1, _param32],  # Push 32 bit param onto the stack
    "parami32": [1, _param32],  # Push 32 bit param onto the stack
    "paramf16": [1, _paramf16],  # Push 32 bit param onto the stack
    "paramf": [1, _paramf],  # Push float param - 6 BYTES (always even) onto the stack
    "paramstr": [1, _paramstr],  # Push float param - 6 BYTES (always even) onto the stack
    "fparamu8": [1, _fparam8],  # __FASTCALL__ parameter
    "fparami8": [1, _fparam8],  # __FASTCALL__ parameter
    "fparamu16": [1, _fparam16],  # __FASTCALL__ parameter
    "fparami16": [1, _fparam16],  # __FASTCALL__ parameter
    "fparamu32": [1, _fparam32],  # __FASTCALL__ parameter
    "fparami32": [1, _fparam32],  # __FASTCALL__ parameter
    "fparamf16": [1, _fparamf16],  # __FASTCALL__ parameter
    "fparamf": [1, _fparamf],  # __FASTCALL__ parameter
    "fparamstr": [1, _fparamstr],  # __FASTCALL__ parameter
    "call": [2, _call],  # Call Address, NNNN --- NNNN = Size (in bytes) of the returned value (0 for procedure)
    "ret": [1, _ret],  # Returns from a function call (enters the 'leave' sequence'), returning no value
    "reti8": [2, _ret8],  # Returns from a function call (enters the 'leave' sequence'), returning 8 bit value
    "retu8": [2, _ret8],  # Returns from a function call (enters the 'leave' sequence'), returning 8 bit value
    "reti16": [2, _ret16],  # Returns from a function call (enters the 'leave' sequence'), returning 16 bit value
    "retu16": [2, _ret16],  # Returns from a function call (enters the 'leave' sequence'), returning 16 bit value
    "reti32": [2, _ret32],  # Returns from a function call (enters the 'leave' sequence'), returning 32 bit value
    "retu32": [2, _ret32],  # Returns from a function call (enters the 'leave' sequence'), returning 32 bit value
    "retf16": [2, _retf16],  # Returns from a function call (enters the 'leave' sequence'), returning fixed point
    "retf": [2, _retf],  # Returns from a function call (enters the 'leave' sequence'), returning fixed point
    "retstr": [2, _retstr],  # Returns from a function call (enters the 'leave' sequence'), returning fixed point
    "leave": [1, _leave],  # LEAVE label, NN -> NN = Size of parameters in bytes (End of function <label>)
    "enter": [1, _enter],  # ENTER procedure/function; NN = size of local variables in bytes (Function beginning)
    "org": [1, _org],  # Defines code location
    "end": [1, _end],  # Defines an end sequence
    "label": [1, _label],  # Defines a label # Flow control instructions
    "deflabel": [2, _deflabel],  # Defines a label with a value
    "out": [2, _out],  # Defines a OUT instruction OUT x, y
    "in": [1, _in],  # Defines an IN instruction IN x, y
    "inline": [1, _inline],  # Defines an inline asm instruction
    "cast": [4, _cast],
    # TYPECAST: X = cast(from Type1, to Type2, Y) Ej. Converts Y 16bit to X 8bit: (cast, x, u16, u8, y)
    "storei8": [2, _store8],  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "storeu8": [2, _store8],  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "storei16": [2, _store16],  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "storeu16": [2, _store16],  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "storei32": [2, _store32],  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "storeu32": [2, _store32],  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "storef16": [2, _storef16],  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "storef": [2, _storef],
    "storestr": [2, _storestr],  # STORE STR1 <-- STR2 : Store string: Reallocs STR1 and then copies STR2 into STR1
    "astorei8": [2, _astore8],  # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "astoreu8": [2, _astore8],  # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "astorei16": [2, _astore16],  # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "astoreu16": [2, _astore16],  # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "astorei32": [2, _astore32],  # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "astoreu32": [2, _astore32],  # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "astoref16": [2, _astoref16],  # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    "astoref": [2, _astoref],
    "astorestr": [2, _astorestr],
    # ARRAY STORE STR1 <-- STR2 : Store string: Reallocs STR1 and then copies STR2 into STR1
    "loadi8": [2, _load8],  # LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
    "loadu8": [2, _load8],  # LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
    "loadi16": [2, _load16],  # LOAD X, nnnn  -> Load memory content at nnnn into X
    "loadu16": [2, _load16],  # LOAD X, nnnn  -> Load memory content at nnnn into X
    "loadi32": [2, _load32],  # LOAD X, nnnn  -> Load memory content at nnnn into X
    "loadu32": [2, _load32],  # LOAD X, nnnn  -> Load memory content at nnnn into X
    "loadf16": [2, _loadf16],  # LOAD X, nnnn  -> Load memory content at nnnn into X
    "loadf": [2, _loadf],  # LOAD X, nnnn  -> Load memory content at nnnn into X
    "loadstr": [2, _loadstr],  # LOAD X, nnnn -> Load string value at nnnn into X
    "aloadi8": [2, _aload8],  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
    "aloadu8": [2, _aload8],  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
    "aloadi16": [2, _aload16],  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    "aloadu16": [2, _aload16],  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    "aloadi32": [2, _aload32],  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    "aloadu32": [2, _aload32],  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    "aloadf16": [2, _aload32],  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    "aloadf": [2, _aloadf],  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    "aloadstr": [2, _aloadstr],  # ARRAY LOAD X, nnnn -> Load string value at nnnn into X
    "pstorei8": [2, _pstore8],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pstoreu8": [2, _pstore8],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pstorei16": [2, _pstore16],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pstoreu16": [2, _pstore16],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pstorei32": [2, _pstore32],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pstoreu32": [2, _pstore32],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pstoref16": [2, _pstoref16],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pstoref": [2, _pstoref],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pstorestr": [2, _pstorestr],  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastorei8": [2, _pastore8],
    # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastoreu8": [2, _pastore8],
    # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastorei16": [2, _pastore16],
    # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastoreu16": [2, _pastore16],
    # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastorei32": [2, _pastore32],
    # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastoreu32": [2, _pastore32],
    # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastoref16": [2, _pastoref16],
    # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastoref": [2, _pastoref],  # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "pastorestr": [2, _pastorestr],
    # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    "ploadi8": [2, _pload8],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "ploadu8": [2, _pload8],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "ploadi16": [2, _pload16],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "ploadu16": [2, _pload16],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "ploadi32": [2, _pload32],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "ploadu32": [2, _pload32],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "ploadf16": [2, _pload32],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "ploadf": [2, _ploadf],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "ploadstr": [2, _ploadstr],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paddr": [2, _paddr],  # LOADS IX + nnnn into the stack
    "aaddr": [2, _aaddr],  # LOADS ADDRESS of global ARRAY element into the stack
    "paaddr": [2, _paaddr],  # LOADS ADDRESS of local ARRAY element into the stack
    "paloadi8": [2, _paload8],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paloadu8": [2, _paload8],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paloadi16": [2, _paload16],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paloadu16": [2, _paload16],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paloadi32": [2, _paload32],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paloadu32": [2, _paload32],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paloadf16": [2, _paload32],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paloadf": [2, _paloadf],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "paloadstr": [2, _paloadstr],  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "fploadstr": [2, _fploadstr],  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    "exchg": [0, _exchg],  # Exchange registers
    "nop": [0, _nop],  # Used to remove (overwrite) instructions during the opt. phase
    "var": [2, _var],  # Declares a variable space (filled with zeroes)
    "varx": [3, _varx],  # Like the above but with a list of items (chars, bytes or words, hex)
    "vard": [2, _vard],  # Like the above but with a list of items (chars, bytes or words, hex)
    "lvarx": [3, _lvarx],  # Initializes a local variable. lvard X, (list of bytes): Initializes variable at offset X
    "lvard": [2, _lvard],  # Initializes a local variable. lvard X, (list of bytes): Initializes variable at offset X
    "larrd": [5, _larrd],  # Initializes a local array
    "memcopy": [3, _memcopy],  # Copies a block of param 3 bytes of memory from param 2 addr to param 1 addr.
    "bandu8": [3, _band8],  # x = A & B
    "bandi8": [3, _band8],  # x = A & B
    "boru8": [3, _bor8],  # x = A | B
    "bori8": [3, _bor8],  # x = A | B
    "bxoru8": [3, _bxor8],  # x = A ^ B
    "bxori8": [3, _bxor8],  # x = A ^ B
    "bnoti8": [2, _bnot8],  # x = !A
    "bnotu8": [2, _bnot8],  # x = !A
    "bandu16": [3, _band16],  # x = A & B
    "bandi16": [3, _band16],  # x = A & B
    "boru16": [3, _bor16],  # x = A | B
    "bori16": [3, _bor16],  # x = A | B
    "bxoru16": [3, _bxor16],  # x = A ^ B
    "bxori16": [3, _bxor16],  # x = A ^ B
    "bnotu16": [2, _bnot16],  # x = A ^ B
    "bnoti16": [2, _bnot16],  # x = A ^ B
    "bandu32": [3, _band32],  # x = A & B
    "bandi32": [3, _band32],  # x = A & B
    "boru32": [3, _bor32],  # x = A | B
    "bori32": [3, _bor32],  # x = A | B
    "bxoru32": [3, _bxor32],  # x = A ^ B
    "bxori32": [3, _bxor32],  # x = A ^ B
    "bnotu32": [2, _bnot32],  # x = A ^ B
    "bnoti32": [2, _bnot32],  # x = A ^ B
}


# -------------------------
# Program Start routine
# -------------------------
def emit_start():
    output = list()
    heap_init = ["%s:" % DATA_LABEL]
    output.append("org %s" % OPTIONS.org)

    if REQUIRES.intersection(MEMINITS) or f"{NAMESPACE}.__MEM_INIT" in INITS:
        heap_init.append("; Defines HEAP SIZE\n" + OPTIONS.heap_size_label + " EQU " + str(OPTIONS.heap_size))
        heap_init.append(OPTIONS.heap_start_label + ":")
        heap_init.append("DEFS %s" % str(OPTIONS.heap_size))

    heap_init.append(
        "; Defines USER DATA Length in bytes\n"
        + f"{NAMESPACE}.ZXBASIC_USER_DATA_LEN EQU {DATA_END_LABEL} - {DATA_LABEL}"
    )
    heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA_LEN EQU {NAMESPACE}.ZXBASIC_USER_DATA_LEN")
    heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA EQU {DATA_LABEL}")

    output.append("%s:" % START_LABEL)
    if OPTIONS.headerless:
        output.extend(heap_init)
        return output

    output.append("di")
    output.append("push ix")
    output.append("push iy")
    output.append("exx")
    output.append("push hl")
    output.append("exx")
    output.append("ld hl, 0")
    output.append("add hl, sp")
    output.append("ld (%s), hl" % CALL_BACK)
    output.append("ei")

    for x in sorted(INITS):
        output.append("call %s" % x)

    output.append("jp %s" % MAIN_LABEL)
    output.append("%s:" % CALL_BACK)
    output.append("DEFW 0")
    output.extend(heap_init)

    return output


def convertToBool():
    """Convert a byte value to boolean (0 or 1) if
    the global flag strictBool is True
    """
    if not OPTIONS.strict_bool:
        return []

    return ["pop af", runtime_call(RuntimeLabel.NORMALIZE_BOOLEAN), "push af"]


def emit_end():
    """This special ending autoinitializes required inits
    (mainly alloc.asm) and changes the MEMORY initial address if it is
    ORG XXXX to ORG XXXX + heap size
    """
    output = []
    output.extend(AT_END)

    if OPTIONS.autorun:
        output.append("END %s" % START_LABEL)
    else:
        output.append("END")

    return output


def remove_unused_labels(output: List[str]):
    labels_used: Dict[str, List[int]] = defaultdict(list)
    labels_to_delete: Dict[str, int] = {}
    labels: Set[str] = set()
    label_alias: Dict[str, str] = {}

    prev = None
    for i, ins in enumerate(output):
        if ins and ins[-1] == ":":
            ins = ins[:-1]
            labels.add(ins)
            if prev is not None:
                if prev not in TMP_LABELS and ins in TMP_LABELS or prev in label_alias:
                    label_alias[ins] = prev
                else:
                    label_alias[prev] = ins
            prev = ins
        else:
            prev = None

    for i, ins in enumerate(output):
        try_label = ins[:-1]
        if try_label in TMP_LABELS:
            if try_label in labels_used:
                labels_to_delete.pop(try_label, None)
            else:
                labels_to_delete[try_label] = i
            continue

        for op in Asm.opers(ins):
            if op in labels:
                new_label = op
                while new_label in label_alias:
                    new_label = label_alias[new_label]

                labels_used[new_label].append(i)
                labels_to_delete.pop(new_label, None)

                if new_label != op:
                    output[i] = re.sub(f"((?<![.a-zA-Z0-9_])){op.replace('.', '[.]')}(?=$|\\s)", new_label, ins)

    for i in sorted(labels_to_delete.values(), reverse=True):
        output.pop(i)


def emit(mem: List[Quad], optimize: bool = True) -> List[str]:
    """Begin converting each quad instruction to asm
    by iterating over the "mem" array, and called its
    associated function. Each function returns an array of
    ASM instructions which will be appended to the
    'output' array
    """
    # Optimization patterns: at this point no more than -O2
    patterns = [x for x in engine.PATTERNS if x.level <= min(OPTIONS.optimization_level, 2)]

    def output_join(output: List[str], new_chunk: List[str]):
        """Extends output instruction list
        performing a little peep-hole optimization (O1)
        """
        base_index = len(output)
        output.extend(new_chunk)

        if not optimize:
            return

        idx = max(0, base_index - engine.MAXLEN)

        while idx < len(output):
            if not engine.apply_match(output, patterns, index=idx):  # Nothing changed
                idx += 1
            else:
                idx = max(0, idx - engine.MAXLEN)

    output: List[str] = []
    for i in mem:
        output_join(output, QUADS[i.quad[0]][1](i))
        if RE_BOOL.match(i.quad[0]):  # If it is a boolean operation convert it to 0/1 if the STRICT_BOOL flag is True
            output_join(output, convertToBool())

    if optimize and OPTIONS.optimization_level > 1:
        remove_unused_labels(output)
        tmp = output
        output = []
        output_join(output, tmp)

    for j in sorted(REQUIRES):
        output.append("#include once <%s>" % j)

    return output  # Caller will save its contents to a file, or whatever
