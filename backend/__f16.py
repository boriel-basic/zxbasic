#!/usr/bin/python
# -*- coding: utf-8 -*-

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 8 bit boolean, arithmetic and
# comparation intermediate-code traductions
# --------------------------------------------------------------

from __common import REQUIRES, is_int, is_float, log2, is_2n, _f_ops
from __32bit import _add32, _sub32, _lti32, _gti32, _gei32, _lei32, _ne32, _eq32
from __32bit import _and32, _xor32, _or32, _not32, _neg32

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


        
def _f16_oper(op1, op2 = None, useBC = False):
    ''' Returns pop sequence for 32 bits operands
    1st operand in HLDE, 2nd operand remains in the stack

    Unlike 8bit and 16bit version, this does not supports
    operands inversion. Since many of the instructions are implemented
    as functions, they must support this.

    However, if 1st operand is integer (immediate) or indirect, the stack
    will be rearranged, so it contains a 32 bit pushed parameter value for the
    subroutine to be called.

    Set useBC = True to use BC instead of HL (useful to leave HL free)
    '''
    output = []
    op = op2 if op2 is not None else op1

    rHL = 'bc' if useBC else 'hl'
    
    indirect = (op[0] == '*')
    if indirect:
        op = op[1:]

    if is_float(op):
        op = float(op)

        if indirect:
            op = int(op) & 0xFFFF
            output.append('ld hl, (%i)' % op)
            output.append('call __ILOAD32')
            REQUIRES.add('iload32.asm')
        else:
            DE, HL = f16(op)
            output.append('ld de, %i' % DE)
            output.append('ld %s, %i' % (rHL, HL))
    else:
        if op[0] == '_':
            output.append('ld %s, (%s)' % (rHL, op))
        else:
            output.append('pop %s' % rHL)

        if indirect:
            output.append('call __ILOAD32')
            REQUIRES.add('iload32.asm')
        else:
            if op[0] == '_':
                output.append('ld de, (%s + 2)' % op)
            else:
                output.append('pop de')


    if op2 is not None and (op1[0] == '*' or is_float(op1)):
        op = op1
        if is_float(op): # An integer must be in the stack. Let's pushit
            DE, HL = f16(op)
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
            
        de, hl = f16(op2)
        output.append('ld de, %04Xh' % de)
        output.append('ld hl, %04Xh' % hl)
        output = _f16_oper(str(op2))
    else:
        output = _f16_oper(op1, op2)

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
            output = _32bit_opers(op1)
            output.append('push de')
            output.append('push hl')
            return output

        if float(op2) == -1:
            return _negf(ins)

    output = _f16_oper(op1, op2)
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
        
    output = _f16_oper(op1, op2)
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

