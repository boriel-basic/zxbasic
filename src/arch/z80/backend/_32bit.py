#!/usr/bin/python
# -*- coding: utf-8 -*-

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 32 bit boolean, arithmetic and
# comparison intermediate-code translation
# --------------------------------------------------------------

from src.api.tmp_labels import tmp_label
from src.arch.z80.backend._8bit import _8bit_oper
from src.arch.z80.backend.common import REQUIRES, _int_ops, is_int, runtime_call
from src.arch.z80.backend.quad import Quad
from src.arch.z80.backend.runtime import Labels as RuntimeLabel

# -----------------------------------------------------
# 32 bits operands
# -----------------------------------------------------


def int32(op):
    """Returns a 32 bit operand converted to 32 bits unsigned int.
    Negative numbers are returned in 2 complement.

    The result is returned in a tuple (DE, HL) => High16, Low16
    """
    result = int(op) & 0xFFFFFFFF
    return result >> 16, result & 0xFFFF


def _32bit_oper(op1, op2=None, *, reversed: bool = False, preserveHL: bool = False) -> list[str]:
    """Returns pop sequence for 32 bits operands
    1st operand in HLDE, 2nd operand remains in the stack

    Now it does support operands inversion calling __SWAP32.

    However, if 1st operand is integer (immediate) or indirect, the stack
    will be rearranged, so it contains a 32 bit pushed parameter value for the
    subroutine to be called.

    If preserveHL is True, then BC will be used instead of HL for lower part
    for the 1st operand.
    """
    output = []

    if op1 is not None:
        op1 = str(op1)

    if op2 is not None:
        op2 = str(op2)

    op = op2 if op2 is not None else op1

    int1 = False  # whether op1 (2nd operand) is integer

    indirect = op[0] == "*"
    if indirect:
        op = op[1:]

    immediate = op[0] == "#"
    if immediate:
        op = op[1:]

    hl = "hl" if not preserveHL and not indirect else "bc"

    if is_int(op):
        int1 = True
        op = int(op)

        if indirect:
            if immediate:
                output.append("ld hl, %i" % op)
            else:
                output.append("ld hl, (%i)" % op)

            output.append(runtime_call(RuntimeLabel.ILOAD32))  # TODO: Is this ever used

            if preserveHL:
                output.append("ld b, h")
                output.append("ld c, l")
        else:
            DE, HL = int32(op)
            output.append("ld de, %i" % DE)
            output.append("ld %s, %i" % (hl, HL))
    else:
        if op[0] == "_":
            if immediate:
                output.append("ld %s, %s" % (hl, op))
            else:
                output.append("ld %s, (%s)" % (hl, op))
        else:
            if immediate:
                output.append("ld %s, (%s) & 0xFFFF" % (hl, op))
            else:
                output.append("pop %s" % hl)

        if indirect:
            output.append(runtime_call(RuntimeLabel.ILOAD32))  # TODO: Is this ever used

            if preserveHL:
                output.append("ld b, h")
                output.append("ld c, l")
        else:
            if op[0] == "_":
                output.append("ld de, (%s + 2)" % op)
            else:
                if immediate:
                    output.append("ld de, (%s) >> 16" % op)
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

        if is_int(op):
            op = int(op)

            if indirect:
                output.append("exx")
                if immediate:
                    output.append("ld hl, %i" % (op & 0xFFFF))
                else:
                    output.append("ld hl, (%i)" % (op & 0xFFFF))

                output.append(runtime_call(RuntimeLabel.ILOAD32))  # TODO: Is this ever used
                output.append("push de")
                output.append("push hl")
                output.append("exx")
            else:
                DE, HL = int32(op)
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

                output.append(runtime_call(RuntimeLabel.ILOAD32))  # TODO: Is this ever used
                output.append("push de")
                output.append("push hl")
                output.append("exx")
            elif immediate:
                output.append("ld bc, (%s) >> 16" % op)
                output.append("push bc")
                output.append("ld bc, (%s) & 0xFFFF" % op)
                output.append("push bc")
            elif op[0] == "_":  # an address
                if int1 or op1[0] == "_":  # If previous op was integer, we can use hl in advance
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


def _bool_32bit_binary(ins, label: str, *, reversible: bool, use_int: bool) -> list[str]:
    op1, op2 = tuple(ins[2:])
    rev = reversible and op1[0] != "t" and not is_int(op1) and op2[0] == "t"

    if use_int and _int_ops(op1, op2):
        op1, op2 = _int_ops(op1, op2)

    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(label))
    output.append("push af")
    return output


def _32bit_unary(ins, label: str) -> list[str]:
    output = _32bit_oper(ins[2])
    output.append(runtime_call(label))
    output.append("push de")
    output.append("push hl")
    return output


def _to_bool() -> list[str]:
    return ["sbc a, a", "neg", "push af"]  # 0 if not Carry, -1 if Carry  # 0 if not Carry (false), 1 if Carry (true),


# -----------------------------------------------------
#               Arithmetic operations
# -----------------------------------------------------


def _add32(ins: Quad) -> list[str]:
    """Pops last 2 bytes from the stack and adds them.
    Then push the result onto the stack.

    Optimizations:
      * If any of the operands is ZERO,
        then do NOTHING: A + 0 = 0 + A = A
    """
    op1, op2 = tuple(ins[2:])

    if _int_ops(op1, op2) is not None:
        o1, o2 = _int_ops(op1, op2)

        if int(o2) == 0:  # A + 0 = 0 + A = A => Do Nothing
            output = _32bit_oper(o1)
            output.append("push de")
            output.append("push hl")
            return output

    if op1[0] == "_" and op2[0] != "_":
        op1, op2 = op2, op1  # swap them

    if op2[0] == "_":
        output = _32bit_oper(op1)
        output.append("ld bc, (%s)" % op2)
        output.append("add hl, bc")
        output.append("ex de, hl")
        output.append("ld bc, (%s + 2)" % op2)
        output.append("adc hl, bc")
        output.append("push hl")
        output.append("push de")
        return output

    output = _32bit_oper(op1, op2)
    output.append("pop bc")
    output.append("add hl, bc")
    output.append("ex de, hl")
    output.append("pop bc")
    output.append("adc hl, bc")
    output.append("push hl")  # High and low parts are reversed
    output.append("push de")

    return output


def _sub32(ins: Quad) -> list[str]:
    """Pops last 2 dwords from the stack and subtract them.
    Then push the result onto the stack.
    NOTE: The operation is TOP[0] = TOP[-1] - TOP[0]

    If TOP[0] is 0, nothing is done
    """
    op1, op2 = tuple(ins[2:])

    if is_int(op2):
        if int(op2) == 0:  # A - 0 = A => Do Nothing
            output = _32bit_oper(op1)
            output.append("push de")
            output.append("push hl")
            return output

    rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"

    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.SUB32))
    output.append("push de")
    output.append("push hl")
    return output


def _mul32(ins: Quad) -> list[str]:
    """Multiplies two last 32bit values on top of the stack and
    and returns the value on top of the stack

    Optimizations done:

        * If any operand is 1, do nothing
        * If any operand is 0, push 0
    """
    op1, op2 = tuple(ins[2:])
    if _int_ops(op1, op2):
        op1, op2 = _int_ops(op1, op2)
        output = _32bit_oper(op1)

        if op2 == 1:
            output.append("push de")
            output.append("push hl")
            return output  # A * 1 = Nothing

        if op2 == 0:
            output.append("ld hl, 0")
            output.append("push hl")
            output.append("push hl")
            return output

    output = _32bit_oper(op1, op2)
    output.append(runtime_call(RuntimeLabel.MUL32))  # Immediate
    output.append("push de")
    output.append("push hl")
    return output


def _divu32(ins: Quad) -> list[str]:
    """Divides 2 32bit unsigned integers. The result is pushed onto the stack.

    Optimizations:

     * If 2nd operand is 1, do nothing
    """
    op1, op2 = tuple(ins[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _32bit_oper(op1)
            output.append("push de")
            output.append("push hl")
            return output

    rev = is_int(op1) or op1[0] == "t" or op2[0] != "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.DIVU32))
    output.append("push de")
    output.append("push hl")
    return output


def _divi32(ins: Quad) -> list[str]:
    """Divides 2 32bit signed integers. The result is pushed onto the stack.

    Optimizations:

     * If 2nd operand is 1, do nothing
     * If 2nd operand is -1, do NEG32
    """
    op1, op2 = tuple(ins[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _32bit_oper(op1)
            output.append("push de")
            output.append("push hl")
            return output

        if int(op2) == -1:
            return _neg32(ins)

    rev = is_int(op1) or op1[0] == "t" or op2[0] != "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.DIVI32))
    output.append("push de")
    output.append("push hl")
    return output


def _modu32(ins: Quad) -> list[str]:
    """Reminder of div. 2 32bit unsigned integers. The result is pushed onto the stack.

    Optimizations:

     * If 2nd op is 1. Returns 0
    """
    op1, op2 = tuple(ins[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _32bit_oper(op1)
            output.append("ld hl, 0")
            output.append("push hl")
            output.append("push hl")
            return output

    rev = is_int(op1) or op1[0] == "t" or op2[0] != "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.MODU32))
    output.append("push de")
    output.append("push hl")
    return output


def _modi32(ins: Quad) -> list[str]:
    """Reminder of div. 2 32bit signed integers. The result is pushed onto the stack.

    Optimizations:

     * If 2nd op is 1. Returns 0
    """
    op1, op2 = tuple(ins[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _32bit_oper(op1)
            output.append("ld hl, 0")
            output.append("push hl")
            output.append("push hl")
            return output

    rev = is_int(op1) or op1[0] == "t" or op2[0] != "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.MODI32))
    output.append("push de")
    output.append("push hl")
    return output


def _ltu32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand < 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit unsigned version
    """
    op1, op2 = tuple(ins[2:])
    rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.SUB32))
    output.append("sbc a, a")
    output.append("push af")
    return output


def _lti32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand < 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit signed version
    """
    return _bool_32bit_binary(ins, RuntimeLabel.LTI32, reversible=True, use_int=False)


def _gtu32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand > 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit unsigned version
    """
    op1, op2 = tuple(ins[2:])
    rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append("pop bc")
    output.append("or a")
    output.append("sbc hl, bc")
    output.append("ex de, hl")
    output.append("pop de")
    output.append("sbc hl, de")
    output.append("sbc a, a")
    output.append("push af")
    return output


def _gti32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand > 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit signed version
    """
    # TODO: Refact this as a call to _lei32() + pop af + ...
    op1, op2 = tuple(ins[2:])
    rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.LEI32))  # Checks A <= B ?
    output.append("sub 1")  # Carry if A = 0 (False)
    output.append("sbc a, a")  # Negates => A > B ?
    output.append("push af")
    return output


def _leu32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand <= 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit unsigned version
    """
    op1, op2 = tuple(ins[2:])
    rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append("pop bc")
    output.append("or a")
    output.append("sbc hl, bc")
    output.append("ex de, hl")
    output.append("pop de")
    output.append("sbc hl, de")  # Carry if A > B
    output.append("ccf")  # Negates result => Carry if A <= B
    output.append("sbc a, a")
    output.append("push af")
    return output


def _lei32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand <= 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit signed version
    """
    return _bool_32bit_binary(ins, RuntimeLabel.LEI32, reversible=True, use_int=False)


def _geu32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand >= 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit unsigned version
    """
    op1, op2 = tuple(ins[2:])
    rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.SUB32))  # Carry if A < B
    output.append("ccf")  # Negates result => Carry if A >= B
    output.append("sbc a, a")
    output.append("push af")
    return output


def _gei32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand >= 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit signed version
    """
    # TODO: Refact this as negated Boolean
    op1, op2 = tuple(ins[2:])
    rev = op1[0] != "t" and not is_int(op1) and op2[0] == "t"
    output = _32bit_oper(op1, op2, reversed=rev)
    output.append(runtime_call(RuntimeLabel.LTI32))  # A = (a < b)
    output.append("sub 1")  # Carry if !(a < b)
    output.append("sbc a, a")  # A = !(a < b) = (a >= b)
    output.append("push af")
    return output


def _eq32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand == 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit un/signed version
    """
    return _bool_32bit_binary(ins, RuntimeLabel.EQ32, reversible=False, use_int=True)


def _ne32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand != 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit un/signed version
    """
    # TODO: Refact this as negation of EQ32
    op1, op2 = tuple(ins[2:])
    output = _32bit_oper(op1, op2)
    output.append(runtime_call(RuntimeLabel.EQ32))
    output.append("sub 1")  # Carry if A = 0 (False)
    output.append("sbc a, a")  # Negates => A > B ?
    output.append("push af")
    return output


def _or32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand OR (Logical) 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit un/signed version
    """
    return _bool_32bit_binary(ins, RuntimeLabel.OR32, reversible=False, use_int=False)


def _bor32(ins: Quad) -> list[str]:
    """Pops top 2 operands out of the stack, and checks
    if the 1st operand OR (Bitwise) 2nd operand (top of the stack).
    Pushes result DE (high) HL (low)

    32 bit un/signed version
    """
    op1, op2 = tuple(ins[2:])
    output = _32bit_oper(op1, op2)
    output.append(runtime_call(RuntimeLabel.BOR32))
    output.append("push de")
    output.append("push hl")
    return output


def _xor32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand XOR (Logical) 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit un/signed version
    """
    return _bool_32bit_binary(ins, RuntimeLabel.XOR32, reversible=False, use_int=False)


def _bxor32(ins: Quad) -> list[str]:
    """Pops top 2 operands out of the stack, and checks
    if the 1st operand XOR (Bitwise) 2nd operand (top of the stack).
    Pushes result DE (high) HL (low)

    32 bit un/signed version
    """
    op1, op2 = tuple(ins[2:])
    output = _32bit_oper(op1, op2)
    output.append(runtime_call(RuntimeLabel.BXOR32))
    output.append("push de")
    output.append("push hl")
    return output


def _and32(ins: Quad) -> list[str]:
    """Compares & pops top 2 operands out of the stack, and checks
    if the 1st operand AND (Logical) 2nd operand (top of the stack).
    Pushes 0 if False, 1 if True.

    32 bit un/signed version
    """
    op1, op2 = tuple(ins[2:])

    if _int_ops(op1, op2):
        op1, op2 = _int_ops(op1, op2)

        if op2 == 0:  # X and False = False  # TODO: Move this to the optimizer
            if str(op1)[0] == "t":  # a temporary term (stack)
                output = _32bit_oper(op1)  # Remove op1 from the stack
            else:
                output = []
            output.append("xor a")
            output.append("push af")
            return output

            # For X and TRUE = X we do nothing as we have to convert it to boolean
            # which is a rather expensive instruction

    return _bool_32bit_binary(ins, RuntimeLabel.AND32, reversible=False, use_int=True)


def _band32(ins: Quad) -> list[str]:
    """Pops top 2 operands out of the stack, and checks
    if the 1st operand AND (Bitwise) 2nd operand (top of the stack).
    Pushes result DE (high) HL (low)

    32 bit un/signed version
    """
    op1, op2 = tuple(ins[2:])
    output = _32bit_oper(op1, op2)
    output.append(runtime_call(RuntimeLabel.BAND32))
    output.append("push de")
    output.append("push hl")
    return output


def _not32(ins: Quad) -> list[str]:
    """Negates top (Logical NOT) of the stack (32 bits in DEHL)"""
    output = _32bit_oper(ins[2])
    output.append(runtime_call(RuntimeLabel.NOT32))
    output.append("push af")
    return output


def _bnot32(ins: Quad) -> list[str]:
    """Negates top (Bitwise NOT) of the stack (32 bits in DEHL)"""
    output = _32bit_oper(ins[2])
    output.append(runtime_call(RuntimeLabel.BNOT32))
    output.append("push de")
    output.append("push hl")
    return output


def _neg32(ins: Quad) -> list[str]:
    """Negates top of the stack (32 bits in DEHL)"""
    return _32bit_unary(ins, RuntimeLabel.NEG32)


def _abs32(ins: Quad) -> list[str]:
    """Absolute value of top of the stack (32 bits in DEHL)"""
    return _32bit_unary(ins, RuntimeLabel.ABS32)


def _shru32(ins: Quad) -> list[str]:
    """Logical Right shift 32bit unsigned integers.
    The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 0, do nothing
    """
    op1, op2 = tuple(ins[2:])

    if is_int(op2):
        output = _32bit_oper(op1)

        if int(op2) == 0:
            output.append("push de")
            output.append("push hl")
            return output

        if int(op2) > 1:
            label = tmp_label()
            output.append("ld b, %s" % op2)
            output.append("%s:" % label)
            output.append(runtime_call(RuntimeLabel.SHRL32))
            output.append("djnz %s" % label)
        else:
            output.append(runtime_call(RuntimeLabel.SHRL32))

        output.append("push de")
        output.append("push hl")
        return output

    output = _8bit_oper(op2)
    output.append("ld b, a")
    output.extend(_32bit_oper(op1))
    label = tmp_label()
    label2 = tmp_label()
    output.append("or a")
    output.append("jr z, %s" % label2)
    output.append("%s:" % label)
    output.append(runtime_call(RuntimeLabel.SHRL32))
    output.append("djnz %s" % label)
    output.append("%s:" % label2)
    output.append("push de")
    output.append("push hl")
    return output


def _shri32(ins: Quad) -> list[str]:
    """Logical Right shift 32bit unsigned integers.
    The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 0, do nothing
    """
    op1, op2 = tuple(ins[2:])

    if is_int(op2):
        output = _32bit_oper(op1)

        if int(op2) == 0:
            output.append("push de")
            output.append("push hl")
            return output

        if int(op2) > 1:
            label = tmp_label()
            output.append("ld b, %s" % op2)
            output.append("%s:" % label)
            output.append(runtime_call(RuntimeLabel.SHRA32))
            output.append("djnz %s" % label)
        else:
            output.append(runtime_call(RuntimeLabel.SHRA32))

        output.append("push de")
        output.append("push hl")
        REQUIRES.add("shra32.asm")
        return output

    output = _8bit_oper(op2)
    output.append("ld b, a")
    output.extend(_32bit_oper(op1))
    label = tmp_label()
    label2 = tmp_label()
    output.append("or a")
    output.append("jr z, %s" % label2)
    output.append("%s:" % label)
    output.append(runtime_call(RuntimeLabel.SHRA32))
    output.append("djnz %s" % label)
    output.append("%s:" % label2)
    output.append("push de")
    output.append("push hl")
    return output


def _shl32(ins: Quad) -> list[str]:
    """Logical Left shift 32bit unsigned integers.
    The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 0, do nothing
    """
    op1, op2 = tuple(ins[2:])

    if is_int(op2):
        output = _32bit_oper(op1)

        if int(op2) == 0:
            output.append("push de")
            output.append("push hl")
            return output

        if int(op2) > 1:
            label = tmp_label()
            output.append("ld b, %s" % op2)
            output.append("%s:" % label)
            output.append(runtime_call(RuntimeLabel.SHL32))
            output.append("djnz %s" % label)
        else:
            output.append(runtime_call(RuntimeLabel.SHL32))

        output.append("push de")
        output.append("push hl")
        return output

    output = _8bit_oper(op2)
    output.append("ld b, a")
    output.extend(_32bit_oper(op1))
    label = tmp_label()
    label2 = tmp_label()
    output.append("or a")
    output.append("jr z, %s" % label2)
    output.append("%s:" % label)
    output.append(runtime_call(RuntimeLabel.SHL32))
    output.append("djnz %s" % label)
    output.append("%s:" % label2)
    output.append("push de")
    output.append("push hl")
    return output


def _load32(ins: Quad) -> list[str]:
    """Load a 32 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    """
    output = _32bit_oper(ins[2])
    output.append("push de")
    output.append("push hl")
    return output


def _store32(ins: Quad) -> list[str]:
    """Stores 2nd operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    """
    op = ins[1]

    indirect = op[0] == "*"
    if indirect:
        op = op[1:]

    immediate = op[0] == "#"  # Might make no sense here?
    if immediate:
        op = op[1:]

    if is_int(op) or op[0] in "_." or immediate:
        output = _32bit_oper(ins[2], preserveHL=indirect)

        if is_int(op):
            op = str(int(op) & 0xFFFF)

        if indirect:
            output.append("ld hl, (%s)" % op)
            output.append(runtime_call(RuntimeLabel.STORE32))  # TODO: is this ever used?
            return output

        output.append("ld (%s), hl" % op)
        output.append("ld (%s + 2), de" % op)

        return output

    output = _32bit_oper(ins[2], preserveHL=True)
    output.append("pop hl")

    if indirect:
        output.append(runtime_call(RuntimeLabel.ISTORE32))  # TODO: is this ever used?

        return output

    output.append(runtime_call(RuntimeLabel.STORE32))
    return output


def _jzero32(ins: Quad) -> list[str]:
    """Jumps if top of the stack (32bit) is 0 to arg(1)"""
    value = ins[1]
    if is_int(value):
        if int(value) == 0:
            return ["jp %s" % str(ins[2])]  # Always true
        else:
            return []

    output = _32bit_oper(value)
    output.append("ld a, h")
    output.append("or l")
    output.append("or e")
    output.append("or d")
    output.append("jp z, %s" % str(ins[2]))
    return output


def _jgezerou32(ins: Quad) -> list[str]:
    """Jumps if top of the stack (23bit) is >= 0 to arg(1)
    Always TRUE for unsigned
    """
    output = []
    value = ins[1]
    if not is_int(value):
        output = _32bit_oper(value)

    output.append("jp %s" % str(ins[2]))
    return output


def _jgezeroi32(ins: Quad) -> list[str]:
    """Jumps if top of the stack (32bit) is >= 0 to arg(1)"""
    value = ins[1]
    if is_int(value):
        if int(value) >= 0:
            return ["jp %s" % str(ins[2])]  # Always true
        else:
            return []

    output = _32bit_oper(value)
    output.append("ld a, d")
    output.append("add a, a")  # Puts sign into carry
    output.append("jp nc, %s" % str(ins[2]))
    return output


def _ret32(ins: Quad) -> list[str]:
    """Returns from a procedure / function a 32bits value (even Fixed point)"""
    output = _32bit_oper(ins[1])
    output.append("#pragma opt require hl,de")
    output.append("jp %s" % str(ins[2]))
    return output


def _param32(ins: Quad) -> list[str]:
    """Pushes 32bit param into the stack"""
    output = _32bit_oper(ins[1])
    output.append("push de")
    output.append("push hl")
    return output


def _fparam32(ins: Quad) -> list[str]:
    """Passes a dword as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate)
    """
    return _32bit_oper(ins[1])


def _jnzero32(ins: Quad) -> list[str]:
    """Jumps if top of the stack (32bit) is !=0 to arg(1)"""
    value = ins[1]
    if is_int(value):
        if int(value) != 0:
            return ["jp %s" % str(ins[2])]  # Always true
        else:
            return []

    output = _32bit_oper(value)
    output.append("ld a, h")
    output.append("or l")
    output.append("or e")
    output.append("or d")
    output.append("jp nz, %s" % str(ins[2]))
    return output
