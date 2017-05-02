#!/usr/bin/python
# -*- coding: utf-8 -*-

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 8 bit boolean, arithmetic and
# comparation intermediate-code traductions
# --------------------------------------------------------------

from .__common import REQUIRES, is_int, is_float, _f_ops
from .__32bit import _add32, _sub32, _lti32, _gti32, _gei32, _lei32, _ne32, _eq32
from .__32bit import _and32, _xor32, _or32, _not32, _neg32

# -----------------------------------------------------
# Fixed Point (16.16) bits operands
# -----------------------------------------------------
def f16(op):
    ''' Returns a floating point operand converted to 32 bits unsigned int.
    Negative numbers are returned in 2 complement.

    The result is returned in a tuple (DE, HL) => High16 (Int part), Low16 (Decimal part)
    '''
    op = float(op)

    negative = op < 0
    if negative:
        op = -op

    DE = int(op)
    HL = int((op - DE) * 2**16) & 0xFFFF
    DE &= 0xFFFF

    if negative: # Do C2
        DE ^= 0xFFFF
        HL ^= 0xFFFF

        DEHL = ((DE << 16) | HL) + 1
        HL = DEHL & 0xFFFF
        DE = (DEHL >> 16) & 0xFFFF

    return (DE, HL)


        
def _f16_oper(op1, op2 = None, useBC = False, reversed = False):
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

    float1 = False # whether op1 (2nd operand) is float
    float2 = False # whether op1 (2nd operand) is float
    
    indirect = (op[0] == '*')
    if indirect:
        op = op[1:]

    immediate = (op[0] == '#')
    if immediate:
        op = op[1:]

    hl = 'hl' if not useBC and not indirect else 'bc'

    if is_float(op):
        float1 = True
        op = float(op)

        if indirect:
            op = int(op) & 0xFFFF
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
            DE, HL = f16(op)
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
        
        if is_float(op):
            float2 = True
            op = float(op)
    
            if indirect:
                op = int(op)
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
                DE, HL = f16(op)
                output.append('ld bc, %i' % DE)
                output.append('push bc')
                output.append('ld bc, %i' % HL)
                output.append('push bc')
        else:
            if indirect:
                output.append('exx') # uses alternate set to put it on the stack
                if op[0] == '_':
                    if immediate:
                        output.append('ld hl, %s' % op)
                    else:
                        output.append('ld hl, (%s)' % op)
                else:
                    output.append('pop hl') # Pointers are only 16 bits ***

                output.append('call __ILOAD32')
                output.append('push de')
                output.append('push hl')
                output.append('exx')
                REQUIRES.add('iload32.asm')
            elif op[0] == '_': # an address
                if float1 or op1[0] == '_': # If previous op was constant, we can use hl in advance
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
                pass # 2nd operand remains in the stack


    if op2 is not None and reversed:
        output.append('call __SWAP32')
        REQUIRES.add('swap32.asm')

    return output



def _f16_to_32bit(ins):
    ''' If any of the operands whithin the ins(truction) are numeric,
    convert them to its 32bit representation, otherwise leave them
    as they are.
    '''
    ins.quad = [x for x in ins.quad]
    for i in range(2, len(ins.quad)):
        if is_float(ins.quad[i]):
            de, hl = f16(ins.quad[i])
            ins.quad[i] = str((de << 16) | hl)

    ins.quad = tuple(ins.quad)
    return ins



def _addf16(ins):
    ''' Pops last 2 bytes from the stack and adds them.
    Then push the result onto the stack.

    Optimizations:
      * If any of the operands is ZERO,
        then do NOTHING: A + 0 = 0 + A = A
    '''
    return _add32(_f16_to_32bit(ins))



def _subf16(ins):
    ''' Pops last 2 dwords from the stack and subtract them.
    Then push the result onto the stack.
    NOTE: The operation is TOP[0] = TOP[-1] - TOP[0]

    If TOP[0] is 0, nothing is done
    '''
    return _sub32(_f16_to_32bit(ins))



def _mulf16(ins):
    ''' Multiplies 2 32bit (16.16) fixed point numbers. The result is pushed onto the stack.
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _f_ops(op1, op2) is not None:
        op1, op2 = _f_ops(op1, op2)

        if op2 == 1: # A * 1 => A
            output = _f16_oper(op1)
            output.append('push de')
            output.append('push hl')
            return output

        if op2 == -1:
            return _neg32(ins)

        output = _f16_oper(op1)
        if op2 == 0:
            output.append('ld hl, 0')
            output.append('ld e, h')
            output.append('ld d, l')
            output.append('push de')
            output.append('push hl')
            return output
            
    output = _f16_oper(op1, str(op2))
    output.append('call __MULF16')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('mulf16.asm')
    return output



def _divf16(ins):
    ''' Divides 2 32bit (16.16) fixed point numbers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd operand is 1, do nothing
         * If 2nd operand is -1, do NEG32
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_float(op2):
        if float(op2) == 1:
            output = _f16_oper(op1)
            output.append('push de')
            output.append('push hl')
            return output

        if float(op2) == -1:
            return _negf(ins)

    rev = not is_float(op1) and op1[0] != 't' and op2[0] == 't'
    
    output = _f16_oper(op1, op2, reversed = rev)
    output.append('call __DIVF16')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('divf16.asm')
    return output



def _modf16(ins):
    ''' Reminder of div. 2 32bit (16.16) fixed point numbers. The result is pushed onto the stack.

        Optimizations:

         * If 2nd op is 1. Returns 0
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        if int(op2) == 1:
            output = _f16b_opers(op1)
            output.append('ld hl, 0')
            output.append('push hl')
            output.append('push hl')
            return output    
        
    rev = not is_float(op1) and op1[0] != 't' and op2[0] == 't'

    output = _f16_oper(op1, op2, reversed = rev)
    output.append('call __MODF16')
    output.append('push de')
    output.append('push hl')
    REQUIRES.add('modf16.asm')
    return output



def _negf16(ins):
    ''' Negates (arithmetic) top of the stack (Fixed point in DE.HL)

        Fixed point signed version
    '''
    return _neg32(_f16_to_32bit(ins))



def _ltf16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _lti32(_f16_to_32bit(ins))



def _gtf16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _gti32(_f16_to_32bit(ins))



def _lef16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _lei32(_f16_to_32bit(ins))



def _gef16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _gei32(_f16_to_32bit(ins))



def _eqf16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _eq32(_f16_to_32bit(ins))



def _nef16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _ne32(_f16_to_32bit(ins))



def _orf16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand OR (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _or32(_f16_to_32bit(ins))



def _xorf16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand XOR (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _xor32(_f16_to_32bit(ins))



def _andf16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand AND (Logical) 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Fixed point signed version
    '''
    return _and32(_f16_to_32bit(ins))



def _notf16(ins):
    ''' Negates top of the stack (Fixed point in DE.HL)

        Fixed point signed version
    '''
    return _not32(_f16_to_32bit(ins))



def _absf16(ins):
    ''' Absolute value of top of the stack (Fixed point in DE.HL)

        Fixed point signed version
    '''
    return _abs32(_f16_to_32bit(ins))

