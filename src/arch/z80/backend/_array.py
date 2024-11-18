# vim:ts=4:et:sw=4:

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains array load/store
# intermediate-code translations
# --------------------------------------------------------------

from ._32bit import Bits32
from ._f16 import Fixed16
from ._float import Float
from .common import REQUIRES, is_int, runtime_call
from .exception import InvalidICError
from .quad import Quad
from .runtime import Labels as RuntimeLabel


def _addr(value: str) -> list[str]:
    """Common subroutine for emitting array address"""
    output = []
    indirect = False

    try:
        if value[0] == "*":
            indirect = True
            value = value[1:]

        value = int(value) & 0xFFFF
        if indirect:
            output.append("ld hl, (%s)" % str(value))
        else:
            output.append("ld hl, %s" % str(value))

    except ValueError:
        if value[0] == "_":
            output.append("ld hl, %s" % str(value))
            if indirect:
                output.append("ld c, (hl)")
                output.append("inc hl")
                output.append("ld h, (hl)")
                output.append("ld l, c")
        else:
            output.append("pop hl")
            if indirect:
                output.append("ld c, (hl)")
                output.append("inc hl")
                output.append("ld h, (hl)")
                output.append("ld l, c")

    output.append(runtime_call(RuntimeLabel.ARRAY))

    return output


def _aaddr(ins: Quad) -> list[str]:
    """Loads the address of an array element
    into the stack.
    """
    output = _addr(ins[2])
    output.append("push hl")

    return output


def _aload8(ins: Quad) -> list[str]:
    """Loads an 8 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _addr(ins[2])
    output.append("ld a, (hl)")
    output.append("push af")

    return output


def _aload16(ins: Quad) -> list[str]:
    """Loads a 16 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _addr(ins[2])

    output.append("ld e, (hl)")
    output.append("inc hl")
    output.append("ld d, (hl)")
    output.append("ex de, hl")
    output.append("push hl")

    return output


def _aload32(ins: Quad) -> list[str]:
    """Load a 32 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _addr(ins[2])

    output.append(runtime_call(RuntimeLabel.ILOAD32))
    output.append("push de")
    output.append("push hl")

    return output


def _aloadf(ins: Quad) -> list[str]:
    """Loads a floating point value from a memory address.
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _addr(ins[2])
    output.append(runtime_call(RuntimeLabel.LOADF))
    output.extend(Float.fpush())

    return output


def _aloadstr(ins: Quad) -> list[str]:
    """Loads a string value from a memory address."""
    output = _addr(ins[2])

    output.append(runtime_call(RuntimeLabel.ILOADSTR))
    output.append("push hl")

    return output


def _astore8(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    1st operand is an array element. Dimensions are pushed into the
    stack.
    Use '*' for indirect store on 1st operand (A pointer to an array)
    """
    output = _addr(ins[1])
    op = ins[2]

    indirect = op[0] == "*"
    if indirect:
        op = op[1:]

    immediate = op[0] == "#"
    if immediate:
        op = op[1:]

    if is_int(op):
        if indirect:
            if immediate:
                op = str(int(op) & 0xFFFF)  # Truncate to 16bit pointer
                output.append("ld a, (%s)" % op)
            else:
                output.append("ld de, (%s)" % op)
                output.append("ld a, (de)")
        else:
            op = str(int(op) & 0xFF)  # Truncate to byte
            output.append("ld (hl), %s" % op)
            return output

    elif op[0] == "_":
        if indirect:
            if immediate:
                output.append("ld a, (%s)" % op)  # Redundant: *#_id == _id
            else:
                output.append("ld de, (%s)" % op)  # *_id
                output.append("ld a, (de)")
        else:
            if immediate:
                output.append("ld a, %s" % op)  # #_id
            else:
                output.append("ld a, (%s)" % op)  # _id
    else:
        output.append("pop af")  # tn

    output.append("ld (hl), a")

    return output


def _astore16(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    Use '*' for indirect store on 1st operand.
    """
    output = _addr(ins[1])
    op = ins[2]

    indirect = op[0] == "*"
    if indirect:
        op = op[1:]

    immediate = op[0] == "#"
    if immediate:
        op = op[1:]

    if is_int(op):
        op = str(int(op) & 0xFFFF)  # Truncate to 16bit pointer

        if indirect:
            if immediate:
                output.append("ld de, (%s)" % op)
            else:
                output.append("ld de, (%s)" % op)
                output.append(runtime_call(RuntimeLabel.LOAD_DE_DE))  # TODO: Check if this is ever used
        else:
            H = int(op) >> 8
            L = int(op) & 0xFF
            output.append("ld (hl), %i" % L)
            output.append("inc hl")
            output.append("ld (hl), %i" % H)
            return output

    elif op[0] == "_":
        if indirect:
            if immediate:
                output.append("ld de, (%s)" % op)  # redundant: *#_id == _id
            else:
                output.append("ld de, (%s)" % op)  # *_id
                output.append(runtime_call(RuntimeLabel.LOAD_DE_DE))  # TODO: Check if this is ever used
        else:
            if immediate:
                output.append("ld de, %s" % op)
            else:
                output.append("ld de, (%s)" % op)
    else:
        output.append("pop de")

    output.append("ld (hl), e")
    output.append("inc hl")
    output.append("ld (hl), d")

    return output


def _astore32(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    """
    output = _addr(ins[1])

    value = ins[2]
    if value[0] == "*":
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        value = int(value) & 0xFFFFFFFF  # Immediate?
        if indirect:
            output.append("push hl")
            output.append("ld hl, %i" % (value & 0xFFFF))
            output.append(runtime_call(RuntimeLabel.ILOAD32))
            output.append("ld b, h")
            output.append("ld c, l")  # BC = Lower 16 bits
            output.append("pop hl")
        else:
            output.append("ld de, %i" % (value >> 16))
            output.append("ld bc, %i" % (value & 0xFFFF))
    except ValueError:
        output.extend(Bits32.get_oper(value, preserveHL=True))

    output.append(runtime_call(RuntimeLabel.STORE32))

    return output


def _astoref16(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    storef16 a, x =>  *(&a) = x
    """
    output = _addr(ins[1])

    value = ins[2]
    if value[0] == "*":
        value = value[1:]
        indirect = True
    else:
        indirect = False

    if indirect:
        output.append("push hl")
        output.extend(Fixed16.get_oper(value, use_bc=True))
        output.append("pop hl")  # TODO: Check if this is ever used
        REQUIRES.add("iload32.asm")  # ?? Nonsense
    else:
        output.extend(Fixed16.get_oper(value, use_bc=True))

    output.append(runtime_call(RuntimeLabel.STORE32))  # TODO: Check if this is ever used

    return output


def _astoref(ins: Quad) -> list[str]:
    """Stores a floating point value into a memory address."""
    output = _addr(ins[1])

    value = ins[2]
    if value[0] == "*":
        value = value[1:]
        indirect = True
    else:
        indirect = False

    if indirect:
        output.append("push hl")
        output.extend(Float.get_oper(ins[2]))
        output.append("pop hl")
    else:
        output.extend(Float.get_oper(ins[2]))

    output.append(runtime_call(RuntimeLabel.STOREF))
    return output


def _astorestr(ins: Quad) -> list[str]:
    """Stores a string value into a memory address.
    It copies content of 2nd operand (string), into 1st, reallocating
    dynamic memory for the 1st str. These instruction DOES ALLOW
    immediate strings for the 2nd parameter, starting with '#'.
    """
    output = _addr(ins[1])
    op = ins[2]

    indirect = op[0] == "*"
    if indirect:
        op = op[1:]

    immediate = op[0] == "#"
    if immediate:
        op = op[1:]

    temporal = op[0] != "$"
    if not temporal:
        op = op[1:]

    if is_int(op):
        op = str(int(op) & 0xFFFF)
        if indirect:
            if immediate:  # *#<addr> = ld hl, (number)
                output.append("ld de, (%s)" % op)
            else:
                output.append("ld de, (%s)" % op)
                output.append(runtime_call(RuntimeLabel.LOAD_DE_DE))  # TODO: Check if this is ever used
        else:
            # Integer does not make sense here (unless it's a ptr)
            raise InvalidICError(str(ins))

    elif op[0] in (".", "_"):  # an identifier
        temporal = False  # Global var is not a temporary string

        if indirect:
            if immediate:  # *#_id = _id
                output.append("ld de, (%s)" % op)
            else:  # *_id
                output.append("ld de, (%s)" % op)
                output.append(runtime_call(RuntimeLabel.LOAD_DE_DE))  # TODO: Check if this is ever used
        else:
            if immediate:
                output.append("ld de, %s" % op)
            else:
                output.append("ld de, (%s)" % op)
    else:  # tn
        output.append("pop de")

        if indirect:
            output.append(runtime_call(RuntimeLabel.LOAD_DE_DE))  # TODO: Check if this is ever used

    if not temporal:
        output.append(runtime_call(RuntimeLabel.STORE_STR))
    else:  # A value already on dynamic memory
        output.append(runtime_call(RuntimeLabel.STORE_STR2))

    return output
