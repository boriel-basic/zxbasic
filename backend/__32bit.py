#!/usr/bin/python
# -*- coding: utf-8 -*-

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 8 bit boolean, arithmetic and
# comparation intermediate-code traductions
# --------------------------------------------------------------

from __common import REQUIRES, is_int, log2, is_2n, _int_ops, tmp_label
from __8bit import _8bit_oper

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


def _32bit_oper(op1, op2 = None, reversed = False):
    ''' Returns pop sequence for 32 bits operands
    1st operand in HLDE, 2nd operand remains in the stack

    Now it does support operands inversion calling __SWAP32.

    However, if 1st operand is integer (immediate) or indirect, the stack
    will be rearranged, so it contains a 32 bit pushed parameter value for the
    subroutine to be called.
    '''
    output = []

    if op1 is not None:
        op1 = str(op1)

    if op2 is not None:
        op2 = str(op2)

    op = op2 if op2 is not None else op1
    
    indirect = (op[0] == '*')
    if indirect:
        op = op[1:]

    if is_int(op):
        op = int(op)

        if indirect:
            output.append('ld hl, (%i)' % op)
            output.append('call __ILOAD32')
            REQUIRES.add('iload32.asm')
        else:
            DE, HL = int32(op)
            output.append('ld de, %i' % DE)
            output.append('ld hl, %i' % HL)
    else:
        if op[0] == '_':
            output.append('ld hl, (%s)' % op)
        else:
            output.append('pop hl')

        if indirect:
            output.append('call __ILOAD32')
            REQUIRES.add('iload32.asm')
        else:
            if op[0] == '_':
                output.append('ld de, (%s + 2)' % op)
            else:
                output.append('pop de')


    if op2 is not None and (op1[0] == '*' or is_int(op1)):
        op = op1
        if is_int(op): # An integer must be in the stack. Let's pushit
            DE, HL = int32(op)
            output.append('ld bc, %i' % DE)
            output.append('push bc')
            output.append('ld bc, %i' % HL)
            output.append('push bc')
        else:
            if op[0] == '*': # Indirect
                op = op[1:]
                output.append('exx') # uses alternate set to put it on the stack
                if is_int(op):
                    op = int(op)
                    output.append('ld hl, %i' % op)
                else:
                    output.append('ld hl, (%s)' % op)

                output.append('call __ILOAD32')
                output.append('push de')
                output.append('push hl')
                output.append('exx')
                REQUIRES.add('iload32.asm')

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
        op1, op2 = _int_ops(op1, op2)

        if int(op2) == 0: # A + 0 = 0 + A = A => Do Nothing
            if op1[0] == '*':
                output = _32bit_oper(op1)
                output.append('push de')
                output.append('push hl')
                return output
            else:
                return []
        # At this point, op2 is the integer one, convert back to integer
        op2 = str(op2)

    output = _32bit_oper(op1, op2)
    output.append('pop bc')
    output.append('add hl, bc')
    output.append('ex de, hl')
    output.append('pop bc')
    output.append('adc hl, bc')
    output.append('push hl') # High and low parts are reversed
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
        if int(op2) == 0: # A - 0 = A => Do Nothing
            if op1[0] == '*':
                output = _32bit_oper(op1)
                output.append('push de')
                output.append('push hl')
                return output
            else:
                return []

    output = _32bit_oper(op1, op2)
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
        
        if op2 == 1:
            if op1[0] == '*':
                output = _32bit_oper(op1)
                output.append('push de')
                output.append('push hl')
            else:
                return []    # A * 1 = Nothing

        if op2 == 0:
            output = []
            output.append('pop hl')
            output.append('pop de')
            output.append('ld hl, 0')
            output.append('push hl')
            output.append('push hl')
            return output

        if op1[0] == '*':
            output = _32bit_oper(op1)
        else:
            output = []

        (DE, HL) = int32(op2)
        output.append('ld de, %i' % DE)
        output.append('ld hl, %i' % HL)
        output.append('call __MUL32')
        output.append('push de')
        output.append('push hl')
        REQUIRES.add('mul32.asm')
        return output

    output = _32bit_oper(op1, op2)
    output.append('call __MUL32') # Inmmediate
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
            if op1[0] == '*':
                output = _32bit_oper(op1)
                output.append('push de')
                output.append('push hl')
                return output
            else:
                return [] # Nothing to do

    output = _32bit_oper(op1, op2, True)
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
            if op1[0] == '*':
                output = _32bit_oper(op1)
                output.append('push de')
                output.append('push hl')
                return output
            else:
                return [] # Nothing to do

        if int(op2) == -1:
            return _neg32(ins)

    output = _32bit_oper(op1, op2, True)
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
        
    output = _32bit_oper(op1, op2, True)
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
        
    output = _32bit_oper(op1, op2, True)
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
    output = _32bit_oper(op1, op2)
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
    output = _32bit_oper(op1, op2)
    output.append('call __SUB32')
    output.append('rl d') # Move bit 31 to carry
    output.append('sbc a, a')
    output.append('push af')
    REQUIRES.add('sub32.asm')
    return output



def _gtu32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit unsigned version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
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
    output = _32bit_oper(op1, op2)
    output.append('pop bc')
    output.append('or a')
    output.append('sbc hl, bc')
    output.append('ex de, hl')
    output.append('pop de')
    output.append('sbc hl, de')
    output.append('add hl, hl') # Moves sign bit to carry
    output.append('sbc a, a')
    output.append('push af')
    return output



def _leu32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit unsigned version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('pop bc')
    output.append('or a')
    output.append('sbc hl, bc')
    output.append('ex de, hl')
    output.append('pop de')
    output.append('sbc hl, de') # Carry if A > B
    output.append('ccf')        # Negates result => Carry if A <= B
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
    output = _32bit_oper(op1, op2)
    output.append('pop bc')
    output.append('or a')
    output.append('sbc hl, bc')
    output.append('ex de, hl')
    output.append('pop de')
    output.append('sbc hl, de')    
    output.append('add hl, hl') # Carry if A > B
    output.append('ccf')        # Negates result => Carry if A <= B
    output.append('sbc a, a')
    output.append('push af')
    return output



def _geu32(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        32 bit unsigned version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _32bit_oper(op1, op2)
    output.append('call __SUB32')    # Carry if A < B
    output.append('ccf')        # Negates result => Carry if A >= B
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
    output = _32bit_oper(op1, op2)
    output.append('call __SUB32')
    output.append('rl d')       # Move bit 31 to carry
    output.append('ccf')        # Negates result => Carry if A >= B
    output.append('sbc a, a')
    output.append('push af')
    REQUIRES.add('sub32.asm')
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
    output.append('cpl')   # Negates the result
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
        
        if op2 == 0:    # X and False = False
            output = _32bit_oper(op1) # Remove op1 from the stack
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
        if int(op2) == 0:
            if op1[0] == '*':
                output = _32bit_oper(op1)
                output.append('push de')
                output.append('push hl')
                return output

            return [] # Nothing to do

        output = _32bit_oper(op1)
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
        if int(op2) == 0:
            if op1[0] == '*':
                output = _32bit_oper(op1)
                output.append('push de')
                output.append('push hl')
                return output

            return [] # Nothing to do

        output = _32bit_oper(op1)
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
        if int(op2) == 0:
            if op1[0] == '*':
                output = _32bit_oper(op1)
                output.append('push de')
                output.append('push hl')
                return output

            return [] # Nothing to do

        output = _32bit_oper(op1)
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

