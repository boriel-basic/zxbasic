#!/usr/bin/python
# -*- coding: utf-8 -*-

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains f16 (fixed) bit boolean, arithmetic and
# comparison intermediate-code translations
# --------------------------------------------------------------

from ._32bit import (
    _abs32,
    _add32,
    _and32,
    _eq32,
    _gei32,
    _gti32,
    _lei32,
    _lti32,
    _ne32,
    _neg32,
    _not32,
    _or32,
    _store32,
    _sub32,
    _xor32,
)
from ._float import _negf
from .common import _f_ops, is_float, runtime_call
from .quad import Quad
from .runtime import Labels as RuntimeLabel


# -----------------------------------------------------
# Fixed Point (16.16) bits operands
# -----------------------------------------------------
def f16(op):
    """Returns a floating point operand converted to 32 bits unsigned int.
    Negative numbers are returned in 2 complement.

    The result is returned in a tuple (DE, HL) => High16 (Int part), Low16 (Decimal part)
    """
    op = float(op)

    negative = op < 0
    if negative:
        op = -op

    DE = int(op)
    HL = int((op - DE) * 2**16) & 0xFFFF
    DE &= 0xFFFF

    if negative:  # Do C2
        DE ^= 0xFFFF
        HL ^= 0xFFFF

        DEHL = ((DE << 16) | HL) + 1
        HL = DEHL & 0xFFFF
        DE = (DEHL >> 16) & 0xFFFF

    return (DE, HL)


def _f16_oper(op1, op2=None, *, useBC: bool = False, reversed: bool = False):
    """Returns pop sequence for 32 bits operands
    1st operand in HLDE, 2nd operand remains in the stack

    Now it does support operands inversion calling __SWAP32.

    However, if 1st operand is integer (immediate) or indirect, the stack
    will be rearranged, so it contains a 32 bit pushed parameter value for the
    subroutine to be called.

    If useBC is True, then BC will be used instead of HL for lower part
    for the 1st operand.
    """
    output = []

    if op1 is not None:
        op1 = str(op1)

    if op2 is not None:
        op2 = str(op2)

    op = op2 if op2 is not None else op1

    float1 = False  # whether op1 (2nd operand) is float

    indirect = op[0] == "*"
    if indirect:
        op = op[1:]

    immediate = op[0] == "#"
    if immediate:
        op = op[1:]

    hl = "hl" if not useBC else "bc"

    if is_float(op):
        float1 = True
        op = float(op)

        if indirect:
            op = int(op) & 0xFFFF
            if immediate:
                output.append("ld hl, %i" % op)
            else:
                output.append("ld hl, (%i)" % op)

            output.append(runtime_call(RuntimeLabel.ILOAD32))
            if useBC:
                output.append("ld b, h")
                output.append("ld c, l")
        else:
            DE, HL = f16(op)
            output.append("ld de, %i" % DE)
            output.append("ld %s, %i" % (hl, HL))
    else:
        if op[0] == "_":
            if immediate:
                output.append("ld %s, %s" % (hl, op))
            else:
                output.append("ld %s, (%s)" % (hl, op))
        else:
            output.append("pop %s" % hl)

        if indirect:
            output.append(runtime_call(RuntimeLabel.ILOAD32))
            if useBC:
                output.append("ld b, h")
                output.append("ld c, l")
        else:
            if op[0] == "_":
                output.append("ld de, (%s + 2)" % op)
            else:
                output.append("pop de")

    if op2 is not None:
        op = op1

        indirect = op[0] == "*"
        if indirect:
            op = op[1:]

        immediate = op[0] == "#"
        if immediate:
            op = op[1:]

        if is_float(op):
            op = float(op)

            if indirect:
                op = int(op)
                output.append("exx")
                if immediate:
                    output.append("ld hl, %i" % (op & 0xFFFF))
                else:
                    output.append("ld hl, (%i)" % (op & 0xFFFF))

                output.append(runtime_call(RuntimeLabel.ILOAD32))  # TODO: Check if this is ever used
                output.append("push de")
                output.append("push hl")
                output.append("exx")
            else:
                DE, HL = f16(op)
                output.append("ld bc, %i" % DE)
                output.append("push bc")
                output.append("ld bc, %i" % HL)
                output.append("push bc")
        else:
            if indirect:
                output.append("exx")  # uses alternate set to put it on the stack
                if op[0] == "_":
                    if immediate:
                        output.append("ld hl, %s" % op)
                    else:
                        output.append("ld hl, (%s)" % op)
                else:
                    output.append("pop hl")  # Pointers are only 16 bits ***

                output.append(runtime_call(RuntimeLabel.ILOAD32))  # TODO: Check if this is ever used
                output.append("push de")
                output.append("push hl")
                output.append("exx")
            elif op[0] == "_":  # an address
                if float1 or op1[0] == "_":  # If previous op was constant, we can use hl in advance
                    tmp = output
                    output = []
                    output.append("ld hl, (%s + 2)" % op)
                    output.append("push hl")
                    output.append("ld hl, (%s)" % op)
                    output.append("push hl")
                    output.extend(tmp)
                else:
                    output.append("ld bc, (%s + 2)" % op)
                    output.append("push bc")
                    output.append("ld bc, (%s)" % op)
                    output.append("push bc")
            else:
                pass  # 2nd operand remains in the stack

    if op2 is not None and reversed:
        output.append(runtime_call(RuntimeLabel.SWAP32))

    return output


def _f16_to_32bit(ins: Quad) -> Quad:
    """If any of the operands within the ins(truction) are numeric,
    convert them to its 32bit representation, otherwise leave them
    as they are.
    """
    quads = list(ins)
    for i, ins in enumerate(quads[1:], 1):
        if is_float(ins):
            de, hl = f16(ins)
            quads[i] = str((de << 16) | hl)

    ins = Quad(*quads)
    return ins


def _f16_binary(ins: Quad, label: str, *, reversible: bool = False) -> list[str]:
    op1, op2 = tuple(ins[2:])
    rev = reversible and not is_float(op1) and op1[0] != "t" and op2[0] == "t"
    output = _f16_oper(op1, op2, reversed=rev)
    output.append(runtime_call(label))
    output.append("push de")
    output.append("push hl")
    return output


def _addf16(ins: Quad) -> list[str]:
    """Pops last 2 bytes from the stack and adds them.
    Then push the result onto the stack.

    Optimizations:
      * If any of the operands is ZERO,
        then do NOTHING: A + 0 = 0 + A = A
    """
    return _add32(_f16_to_32bit(ins))


def _subf16(ins: Quad) -> list[str]:
    """Pops last 2 dwords from the stack and subtract them.
    Then push the result onto the stack.
    NOTE: The operation is TOP[0] = TOP[-1] - TOP[0]

    If TOP[0] is 0, nothing is done
    """
    return _sub32(_f16_to_32bit(ins))


def _mulf16(ins: Quad) -> list[str]:
    """Multiplies 2 32bit (16.16) fixed point numbers. The result is pushed onto the stack."""
    op1, op2 = tuple(ins[2:])

    if _f_ops(op1, op2) is not None:  # TODO: move this to the optimizer
        op1, op2 = _f_ops(op1, op2)

        if op2 == 1:  # A * 1 => A
            output = _f16_oper(op1)
            output.append("push de")
            output.append("push hl")
            return output

        if op2 == -1:
            return _neg32(ins)

        output = _f16_oper(op1)
        if op2 == 0:
            output.append("ld hl, 0")
            output.append("ld e, h")
            output.append("ld d, l")
            output.append("push de")
            output.append("push hl")
            return output

    return _f16_binary(ins, RuntimeLabel.MULF16)


def _divf16(ins: Quad) -> list[str]:
    """Divides 2 32bit (16.16) fixed point numbers. The result is pushed onto the stack.

    Optimizations:

     * If 2nd operand is 1, do nothing
     * If 2nd operand is -1, do NEG32
    """
    op1, op2 = tuple(ins[2:])

    if is_float(op2):
        if float(op2) == 1:  # TODO move this to the optimizer
            output = _f16_oper(op1)
            output.append("push de")
            output.append("push hl")
            return output

        if float(op2) == -1:
            return _negf(ins)

    return _f16_binary(ins, RuntimeLabel.DIVF16, reversible=True)


def _modf16(ins: Quad) -> list[str]:
    """Reminder of div. 2 32bit (16.16) fixed point numbers. The result is pushed onto the stack.
    Optimizations:
     * If 2nd op is 1. Returns 0
    """
    op1, op2 = tuple(ins[2:])

    if is_float(op2) and float(op2) == 1:  # TODO move this to the optimizer
        output = _f16_oper(op1)
        output.append("ld hl, 0")
        output.append("push hl")
        output.append("push hl")
        return output

    return _f16_binary(ins, RuntimeLabel.MODF16, reversible=True)


def _negf16(ins: Quad) -> list[str]:
    """Negates (arithmetic) top of the stack (Fixed point in DE.HL)

    Fixed point signed version
    """
    return _neg32(_f16_to_32bit(ins))


def _ltf16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand < 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _lti32(_f16_to_32bit(ins))


def _gtf16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand > 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _gti32(_f16_to_32bit(ins))


def _lef16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand <= 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _lei32(_f16_to_32bit(ins))


def _gef16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand >= 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _gei32(_f16_to_32bit(ins))


def _eqf16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand == 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _eq32(_f16_to_32bit(ins))


def _nef16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand != 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _ne32(_f16_to_32bit(ins))


def _orf16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand OR (Logical) 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _or32(_f16_to_32bit(ins))


def _xorf16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand XOR (Logical) 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _xor32(_f16_to_32bit(ins))


def _andf16(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand AND (Logical) 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    Fixed point signed version
    """
    return _and32(_f16_to_32bit(ins))


def _notf16(ins: Quad) -> list[str]:
    """Negates top of the stack (Fixed point in DE.HL)

    Fixed point signed version
    """
    return _not32(_f16_to_32bit(ins))


def _absf16(ins: Quad) -> list[str]:
    """Absolute value of top of the stack (Fixed point in DE.HL)

    Fixed point signed version
    """
    return _abs32(_f16_to_32bit(ins))


def _loadf16(ins: Quad) -> list[str]:
    """Load a 32 bit (16.16) fixed point value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _f16_oper(ins[2])
    output.append("push de")
    output.append("push hl")
    return output


def _storef16(ins: Quad) -> list[str]:
    """Stores 2º operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    """
    value = ins[2]
    if is_float(value):
        val = float(ins[2])  # Immediate?
        (de, hl) = f16(val)
        q = list(ins)
        q[2] = (de << 16) | hl
        ins = Quad(*q)

    return _store32(ins)


def _jzerof16(ins: Quad) -> list[str]:
    """Jumps if top of the stack (32bit) is 0 to arg(1)
    (For Fixed point 16.16 bit values)
    """
    value = ins[1]
    if is_float(value):
        if float(value) == 0:
            return ["jp %s" % str(ins[2])]  # Always true
        else:
            return []

    output = _f16_oper(value)
    output.append("ld a, h")
    output.append("or l")
    output.append("or e")
    output.append("or d")
    output.append("jp z, %s" % str(ins[2]))
    return output


def _jnzerof16(ins: Quad) -> list[str]:
    """Jumps if top of the stack (32bit) is !=0 to arg(1)
    Fixed Point (16.16 bit) values.
    """
    value = ins[1]
    if is_float(value):
        if float(value) != 0:
            return ["jp %s" % str(ins[2])]  # Always true
        else:
            return []

    output = _f16_oper(value)
    output.append("ld a, h")
    output.append("or l")
    output.append("or e")
    output.append("or d")
    output.append("jp nz, %s" % str(ins[2]))
    return output


def _jgezerof16(ins: Quad) -> list[str]:
    """Jumps if top of the stack (32bit, fixed point) is >= 0 to arg(1)"""
    value = ins[1]
    if is_float(value):
        if float(value) >= 0:
            return ["jp %s" % str(ins[2])]  # Always true

    output = _f16_oper(value)
    output.append("ld a, d")
    output.append("add a, a")  # Puts sign into carry
    output.append("jp nc, %s" % str(ins[2]))
    return output


def _retf16(ins: Quad) -> list[str]:
    """Returns from a procedure / function a Fixed Point (32bits) value"""
    output = _f16_oper(ins[1])
    output.append("#pragma opt require hl,de")
    output.append("jp %s" % str(ins[2]))
    return output


def _paramf16(ins: Quad) -> list[str]:
    """Pushes 32bit fixed point param into the stack"""
    output = _f16_oper(ins[1])
    output.append("push de")
    output.append("push hl")
    return output


def _fparamf16(ins: Quad) -> list[str]:
    """Passes a 16.16 fixed point as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate)
    """
    return _f16_oper(ins[1])
