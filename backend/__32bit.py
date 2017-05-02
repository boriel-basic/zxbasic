#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 8 bit boolean, arithmetic and
# comparation intermediate-code traductions
# --------------------------------------------------------------

from .__common import REQUIRES, is_int, _int_ops, tmp_label
from .__8bit import _8bit_oper


# -----------------------------------------------------
# 32 bits operands
# -----------------------------------------------------


def int32(op):
    ''' Returns a 32 bit operand converted to 32 bits unsigned int.
    Negative numbers are returned in 2 complement.

    The result is returned in a tuple (DE, HL) => High16, Low16
    '''
    result = int(op) & 0xFFFFFFFF
    return (result >> 16, result & 0xFFFF)


def _32bit_oper(op1, op2=None, reversed=False, preserveHL=False):
    ''' Returns pop sequence for 32 bits operands
    1st operand in HLDE, 2nd operand remains in the stack

    Now it does support operands inversion calling __SWAP32.

    However, if 1st operand is integer (immediate) or indirect, the stack
    will be rearranged, so it contains a 32 bit pushed parameter value for the
    subroutine to be called.

    If preserveHL is True, then BC will be used instead of HL for lower part
    for the 1st operand.
    '''
    output = []

    if op1 is not None:
        op1 = str(op1)

    if op2 is not None:
        op2 = str(op2)

    op = op2 if op2 is not None else op1

    int1 = False  # whether op1 (2nd operand) is integer
    int2 = False  # whether op1 (2nd operand) is integer

    indirect = (op[0] == '*')
    if indirect:
        op = op[1:]

    immediate = (op[0] == '#')
    if immediate:
        op = op[1:]

    hl = 'hl' if not preserveHL and not indirect else 'bc'

    if is_int(op):
        int1 = True
        op = int(op)

        if indirect:
            if immediate:
                output.append('ld hl, %i' % op)
            else:
                output.append('ld hl, (%i)' % op)

            output.append('call __ILOAD32')
            REQUIRES.add('iload32.asm')

            if preserveHL:
                output.append('ld b, h')
                output.append('ld c, l')
        else:
            DE, HL = int32(op)
            output.append('ld de, %i' % DE)
            output.append('ld %s, %i' % (hl, HL))
    else:
        if op[0] == '_':
            if immediate:
                output.append('ld %s, %s' % (hl, op))
            else:
                output.append('ld %s, (%s)' % (hl, op))
        else:
            output.append('pop %s' % hl)

        if indirect:
            output.append('call __ILOAD32')
            REQUIRES.add('iload32.asm')

            if preserveHL:
                output.append('ld b, h')
                output.append('ld c, l')
        else:
            if op[0] == '_':
                output.append('ld de, (%s + 2)' % op)
            else:
                output.append('pop de')

    if op2 is not None:
        op = op1

        indirect = (op[0] == '*')
        if indirect:
            op = op[1:]

        immediate = (op[0] == '#')
        if immediate:
            op = op[1:]

        if is_int(op):
            int2 = True
            op = int(op)

            if indirect:
                output.append('exx')
                if immediate:
                    output.append('ld hl, %i' % (op & 0xFFFF))
                else:
                    output.append('ld hl, (%i)' % (op & 0xFFFF))

                output.append('call __ILOAD32')
                output.append('push de')
                output.append('push hl')
                output.append('exx')
                REQUIRES.add('iload32.asm')
            else:
                DE, HL = int32(op)
                output.append('ld bc, %i' % DE)
                output.append('push bc')
                output.append('ld bc, %i' % HL)
                output.append('push bc')
        else:
            if indirect:
                output.append('exx')  # uses alternate set to put it on the stack
                if op[0] == '_':
                    if immediate:
                        output.append('ld hl, %s' % op)
                    else:
                        output.append('ld hl, (%s)' % op)
                else:
                    output.append('pop hl')  # Pointers are only 16 bits ***

                output.append('call __ILOAD32')
                output.append('push de')
                output.append('push hl')
                output.append('exx')
                REQUIRES.add('iload32.asm')
            elif op[0] == '_':  # an address
                if int1 or op1[0] == '_':  # If previous op was integer, we can use hl in advance
                    tmp = output
                    output = []
                    output.append('ld hl, (%s + 2)' % op)
                    output.append('push hl')
                    output.append('ld hl, (%s)' % op)
                    output.append('push hl')
                    output.extend(tmp)
                else:
                    output.append('ld bc, (%s + 2)' % op)
                    output.append('push bc')
                    output.append('ld bc, (%s)' % op)
                    output.append('push bc')
            else:
                pass  # 2nd operand remains in the stack

    if op2 is not None and reversed:
        output.append('call __SWAP32')
        REQUIRES.add('swap32.asm')

    return output


# -----------------------------------------------------
#               Arithmetic operations
# -----------------------------------------------------

def _add32(ins):
    ''' Pops last 2 bytes from the stack and adds them.
    Then push the result onto the stack.

    Optimizations:
      * If any of the operands is ZERO,
        then do NOTHING: A + 0 = 0 + A = A
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _int_ops(op1, op2) is not None:
        o1, o2 = _int_ops(op1, op2)

        if int(o2) == 0:  # A + 0 = 0 + A = A => Do Nothing
            output = _32bit_oper(o1)
            output.append('push de')
            output.append('push hl')
            return output

    if op1[0] == '_' and op2[0] != '_':
        op1, op2 = op2, op1  # swap them

    if op2[0] == '_':
        output = _32bit_oper(op1)
        output.append('ld bc, (%s)' % op2)
        output.append('add hl, bc')
        output.append('ex de, hl')
        output.append('ld bc, (%s + 2)' % op2)
        output.append('adc hl, bc')
        output.append('push hl')
        output.append('push de')
        return output

    output = _32bit_oper(op1, op2)
    output.append('pop bc')
    output.append('add hl, bc')
    output.append('ex de, hl')
    output.append('pop bc')
    output.append('adc hl, bc')
    output.append('push hl')  # High and low parts are reversed
    output.append('push de')

    return output


def _sub32(ins):
    ''' Pops last 2 dwords from the stack and subtract them.
    Then push the result onto the stack.
    NOTE: The operation is TOP[0] = TOP[-1] - TOP[0]

    If TOP[0] is 0, nothing is done
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        if int(op2) == 0:  # A - 0 = A => Do Nothing
            output = _32bit_oper(op1)
            output.append('push de')
            output.append('push hl')
            return output

    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'

    output = _32bit_oper(op1, op2, rev)
    output.append('call __SUB32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('sub32.asm')
    return output


def _mul32(ins):
    ''' Multiplies two last 32bit values on top of the stack and
    and returns the value on top of the stack

    Optimizations done:
    
        * If any operand is 1, do nothing
        * If any operand is 0, push 0
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2):
        op1, op2 = _int_ops(op1, op2)
        output = _32bit_oper(op1)

        if op2 == 1:
            output.append('push de')
            output.append('push hl')
            return output  # A * 1 = Nothing

        if op2 == 0:
            output.append('ld hl, 0')
            output.append('push hl')
            output.append('push hl')
            return output

    output = _32bit_oper(op1, op2)
    output.append('call __MUL32')  # Inmmediate
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('mul32.asm')
    return output


def _divu32(ins):
    ''' Divides 2 32bit unsigned integers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 1, do nothing
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _32bit_oper(op1)
            output.append('push de')
            output.append('push hl')
            return output

    rev = is_int(op1) or op1[0] == 't' or op2[0] != 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __DIVU32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('div32.asm')
    return output


def _divi32(ins):
    ''' Divides 2 32bit signed integers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 1, do nothing
         * If 2nd operand is -1, do NEG32
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _32bit_oper(op1)
            output.append('push de')
            output.append('push hl')
            return output

        if int(op2) == -1:
            return _neg32(ins)

    rev = is_int(op1) or op1[0] == 't' or op2[0] != 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __DIVI32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('div32.asm')
    return output


def _modu32(ins):
    ''' Reminder of div. 2 32bit unsigned integers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd op is 1. Returns 0
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _32bit_oper(op1)
            output.append('ld hl, 0')
            output.append('push hl')
            output.append('push hl')
            return output

    rev = is_int(op1) or op1[0] == 't' or op2[0] != 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __MODU32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('div32.asm')
    return output


def _modi32(ins):
    ''' Reminder of div. 2 32bit signed integers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd op is 1. Returns 0
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _32bit_oper(op1)
            output.append('ld hl, 0')
            output.append('push hl')
            output.append('push hl')
            return output

    rev = is_int(op1) or op1[0] == 't' or op2[0] != 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __MODI32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('div32.asm')
    return output


def _ltu32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit unsigned version
    '''
    op1, op2 = tuple(ins.quad[2:])
    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __SUB32')
    output.append('sbc a, a')
    output.append('push af')
    REQUIRES.add('sub32.asm')
    return output


def _lti32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __LTI32')
    output.append('push af')
    REQUIRES.add('lti32.asm')
    return output


def _gtu32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit unsigned version
    '''
    op1, op2 = tuple(ins.quad[2:])
    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('pop bc')
    output.append('or a')
    output.append('sbc hl, bc')
    output.append('ex de, hl')
    output.append('pop de')
    output.append('sbc hl, de')
    output.append('sbc a, a')
    output.append('push af')
    return output


def _gti32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __LEI32')  # Checks A <= B ?
    output.append('sub 1')  # Carry if A = 0 (False)
    output.append('sbc a, a')  # Negates => A > B ?
    output.append('push af')
    REQUIRES.add('lei32.asm')
    return output


def _leu32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit unsigned version
    '''
    op1, op2 = tuple(ins.quad[2:])
    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('pop bc')
    output.append('or a')
    output.append('sbc hl, bc')
    output.append('ex de, hl')
    output.append('pop de')
    output.append('sbc hl, de')  # Carry if A > B
    output.append('ccf')  # Negates result => Carry if A <= B
    output.append('sbc a, a')
    output.append('push af')
    return output


def _lei32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __LEI32')
    output.append('push af')
    REQUIRES.add('lei32.asm')
    return output


def _geu32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit unsigned version
    '''
    op1, op2 = tuple(ins.quad[2:])
    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __SUB32')  # Carry if A < B
    output.append('ccf')  # Negates result => Carry if A >= B
    output.append('sbc a, a')
    output.append('push af')
    REQUIRES.add('sub32.asm')
    return output


def _gei32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    rev = op1[0] != 't' and not is_int(op1) and op2[0] == 't'
    output = _32bit_oper(op1, op2, rev)
    output.append('call __LTI32')  # A = (a < b)
    output.append('sub 1')  # Carry if !(a < b)
    output.append('sbc a, a')  # A = !(a < b) = (a >= b)
    output.append('push af')
    REQUIRES.add('lti32.asm')
    return output


def _eq32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('call __EQ32')
    output.append('push af')
    REQUIRES.add('eq32.asm')
    return output


def _ne32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('call __EQ32')
    output.append('cpl')  # Negates the result
    output.append('push af')
    REQUIRES.add('eq32.asm')
    return output


def _or32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand OR (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('call __OR32')
    output.append('push af')
    REQUIRES.add('or32.asm')
    return output


def _bor32(ins):
    ''' Pops top 2 operands out of the stack, and checks
        if the 1st operand OR (Bitwise) 2nd operand (top of the stack).
        Pushes result DE (high) HL (low)

        32 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('call __BOR32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('bor32.asm')
    return output


def _xor32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand XOR (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('call __XOR32')
    output.append('push af')
    REQUIRES.add('xor32.asm')
    return output


def _bxor32(ins):
    ''' Pops top 2 operands out of the stack, and checks
        if the 1st operand XOR (Bitwise) 2nd operand (top of the stack).
        Pushes result DE (high) HL (low)

        32 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('call __BXOR32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('bxor32.asm')
    return output


def _and32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand AND (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _int_ops(op1, op2):
        op1, op2 = _int_ops(op1, op2)

        if op2 == 0:  # X and False = False
            if str(op1)[0] == 't':  # a temporary term (stack)
                output = _32bit_oper(op1)  # Remove op1 from the stack
            else:
                output = []
            output.append('xor a')
            output.append('push af')
            return output

            # For X and TRUE = X we do nothing as we have to convert it to boolean
            # which is a rather expensive instruction

    output = _32bit_oper(op1, op2)
    output.append('call __AND32')
    output.append('push af')
    REQUIRES.add('and32.asm')
    return output


def _band32(ins):
    ''' Pops top 2 operands out of the stack, and checks
        if the 1st operand AND (Bitwise) 2nd operand (top of the stack).
        Pushes result DE (high) HL (low)

        32 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('call __BAND32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('band32.asm')
    return output


def _not32(ins):
    ''' Negates top (Logical NOT) of the stack (32 bits in DEHL)
    '''
    output = _32bit_oper(ins.quad[2])
    output.append('call __NOT32')
    output.append('push af')
    REQUIRES.add('not32.asm')
    return output


def _bnot32(ins):
    ''' Negates top (Bitwise NOT) of the stack (32 bits in DEHL)
    '''
    output = _32bit_oper(ins.quad[2])
    output.append('call __BNOT32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('bnot32.asm')
    return output


def _neg32(ins):
    ''' Negates top of the stack (32 bits in DEHL)
    '''
    output = _32bit_oper(ins.quad[2])
    output.append('call __NEG32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('neg32.asm')
    return output


def _abs32(ins):
    ''' Absolute value of top of the stack (32 bits in DEHL)
    '''
    output = _32bit_oper(ins.quad[2])
    output.append('call __ABS32')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('abs32.asm')
    return output


def _shru32(ins):
    ''' Logical Right shift 32bit unsigned integers.
    The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 0, do nothing
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        output = _32bit_oper(op1)

        if int(op2) == 0:
            output.append('push de')
            output.append('push hl')
            return output

        if int(op2) > 1:
            label = tmp_label()
            output.append('ld b, %s' % op2)
            output.append('%s:' % label)
            output.append('call __SHRL32')
            output.append('djnz %s' % label)
        else:
            output.append('call __SHRL32')

        output.append('push de')
        output.append('push hl')
        REQUIRES.add('shrl32.asm')
        return output

    output = _8bit_oper(op2)
    output.append('ld b, a')
    output.extend(_32bit_oper(op1))
    label = tmp_label()
    output.append('%s:' % label)
    output.append('call __SHRL32')
    output.append('djnz %s' % label)
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('shrl32.asm')
    return output


def _shri32(ins):
    ''' Logical Right shift 32bit unsigned integers.
    The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 0, do nothing
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        output = _32bit_oper(op1)

        if int(op2) == 0:
            output.append('push de')
            output.append('push hl')
            return output

        if int(op2) > 1:
            label = tmp_label()
            output.append('ld b, %s' % op2)
            output.append('%s:' % label)
            output.append('call __SHRA32')
            output.append('djnz %s' % label)
        else:
            output.append('call __SHRA32')

        output.append('push de')
        output.append('push hl')
        REQUIRES.add('shra32.asm')
        return output

    output = _8bit_oper(op2)
    output.append('ld b, a')
    output.extend(_32bit_oper(op1))
    label = tmp_label()
    output.append('%s:' % label)
    output.append('call __SHRA32')
    output.append('djnz %s' % label)
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('shra32.asm')
    return output


def _shl32(ins):
    ''' Logical Left shift 32bit unsigned integers.
    The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 0, do nothing
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        output = _32bit_oper(op1)

        if int(op2) == 0:
            output.append('push de')
            output.append('push hl')
            return output

        if int(op2) > 1:
            label = tmp_label()
            output.append('ld b, %s' % op2)
            output.append('%s:' % label)
            output.append('call __SHL32')
            output.append('djnz %s' % label)
        else:
            output.append('call __SHL32')

        output.append('push de')
        output.append('push hl')
        REQUIRES.add('shl32.asm')
        return output

    output = _8bit_oper(op2)
    output.append('ld b, a')
    output.extend(_32bit_oper(op1))
    label = tmp_label()
    output.append('%s:' % label)
    output.append('call __SHL32')
    output.append('djnz %s' % label)
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('shl32.asm')
    return output
