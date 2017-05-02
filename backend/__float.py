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

from .__common import REQUIRES, is_float, _f_ops

# -----------------------------------------------------
# Floating Point operators
# -----------------------------------------------------
from api import fp


def _float(op):
    ''' Returns a floating point operand converted to 5 byte (40 bits) unsigned int.
    The result is returned in a tuple (C, DE, HL) => Exp, mantissa =>High16 (Int part), Low16 (Decimal part)
    '''
    return fp.immediate_float(float(op))


def _fpop():
    ''' Returns the pop sequence of a float
    '''
    output = []
    output.append('pop af')
    output.append('pop de')
    output.append('pop bc')

    return output


def _fpush():
    ''' Returns the push sequence of a float
    '''
    output = []
    output.append('push bc')
    output.append('push de')
    output.append('push af')

    return output


def _float_oper(op1, op2 = None):
    ''' Returns pop sequence for floating point operands
    1st operand in A DE BC, 2nd operand remains in the stack

    Unlike 8bit and 16bit version, this does not supports
    operands inversion. Since many of the instructions are implemented
    as functions, they must support this.

    However, if 1st operand is a number (immediate) or indirect, the stack
    will be rearranged, so it contains a 48 bit pushed parameter value for the
    subroutine to be called.
    '''
    output = []
    op = op2 if op2 is not None else op1

    indirect = (op[0] == '*')
    if indirect:
        op = op[1:]

    if is_float(op):
        op = float(op)

        if indirect:
            op = int(op) & 0xFFFF
            output.append('ld hl, (%i)' % op)
            output.append('call __ILOADF')
            REQUIRES.add('iloadf.asm')
        else:
            A, DE, BC = _float(op)
            output.append('ld a, %s' % A)
            output.append('ld de, %s' % DE)
            output.append('ld bc, %s' % BC)
    else:
        if indirect:
            if op[0] == '_':
                output.append('ld hl, (%s)' % op)
            else:
                output.append('pop hl')
                
            output.append('call __ILOADF')
            REQUIRES.add('iloadf.asm')
        else:
            if op[0] == '_':
                output.append('ld a, (%s)' % op)
                output.append('ld de, (%s + 1)' % op)
                output.append('ld bc, (%s + 3)' % op)
            else:
                output.extend(_fpop())

    if op2 is not None: 
        op = op1
        if is_float(op): # An float must be in the stack. Let's pushit
            A, DE, BC = _float(op)
            output.append('ld hl, %s' % BC)
            output.append('push hl')
            output.append('ld hl, %s' % DE)
            output.append('push hl')
            output.append('ld h, %s' % A)
            output.append('push hl')
        elif op[0] == '*': # Indirect
            op = op[1:]
            output.append('exx') # uses alternate set to put it on the stack
            output.append("ex af, af'")
            if is_int(op):
                op = int(op)
                output.append('ld hl, %i' % op)
            elif op[0] == '_':
                output.append('ld hl, (%s)' % op)
            else:
                output.append('pop hl')

            output.append('call __ILOADF')
            output.extend(_fpush())
            output.append("ex af, af'")
            output.append('exx')
            REQUIRES.add('iloadf.asm')
        elif op[0] == '_':
            if is_float(op2):
                tmp = output
                output = []
                output.append('ld hl, %s + 4' % op)
                '''
                output.append('ld hl, (%s + 3)' % op)
                output.append('push hl')            
                output.append('ld hl, (%s + 1)' % op)
                output.append('push hl')
                output.append('ld a, (%s)' % op)
                output.append('push af')            
                '''
                output.append('call __FP_PUSH_REV')
                output.extend(tmp)
                REQUIRES.add('pushf.asm')
            else:
                '''
                output.append('ld hl, (%s + 3)' % op)
                output.append('push hl')            
                output.append('ld hl, (%s + 1)' % op)
                output.append('push hl')
                output.append('ld hl, (%s - 1)' % op)
                output.append('push hl')            
                '''
                output.append('ld hl, %s + 4' % op)
                output.append('call __FP_PUSH_REV')
                REQUIRES.add('pushf.asm')
        else:
            pass # Else do nothing, and leave the op onto the stack

    return output


# -----------------------------------------------------
#               Arithmetic operations                  
# -----------------------------------------------------

def _addf(ins):
    ''' Adds 2 float values. The result is pushed onto the stack.
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _f_ops(op1, op2) is not None:
        opa, opb = _f_ops(op1, op2)
        if opb == 0: # A + 0 => A
            output = _float_oper(opa)
            output.extend(_fpush())
            return output

    output = _float_oper(op1, op2)
    output.append('call __ADDF')
    output.extend(_fpush())
    REQUIRES.add('addf.asm')
    return output



def _subf(ins):
    ''' Subtract 2 float values. The result is pushed onto the stack.
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_float(op2) and float(op2) == 0: # Nothing to do: A - 0 = A
        output = _float_oper(op1)
        output.extend(_fpush())
        return output

    output = _float_oper(op1, op2)
    output.append('call __SUBF')
    output.extend(_fpush())
    REQUIRES.add('subf.asm')
    return output



def _mulf(ins):
    ''' Multiplie 2 float values. The result is pushed onto the stack.
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _f_ops(op1, op2) is not None:
        opa, opb = _f_ops(op1, op2)
        if opb == 1: # A * 1 => A
            output = _float_oper(opa)
            output.extend(_fpush())
            return output

    output = _float_oper(op1, op2)
    output.append('call __MULF')
    output.extend(_fpush())
    REQUIRES.add('mulf.asm')
    return output



def _divf(ins):
    ''' Divides 2 float values. The result is pushed onto the stack.
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_float(op2) and float(op2) == 1: # Nothing to do. A / 1 = A
        output = _float_oper(op1)
        output.extend(_fpush())
        return output

    output = _float_oper(op1, op2)
    output.append('call __DIVF')
    output.extend(_fpush())
    REQUIRES.add('divf.asm')
    return output



def _modf(ins):
    ''' Reminder of div. 2 float values. The result is pushed onto the stack.
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __MODF')
    output.extend(_fpush())
    REQUIRES.add('modf.asm')
    return output



def _powf(ins):
    ''' Exponentiation of 2 float values. The result is pushed onto the stack.
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_float(op2) and float(op2) == 1: # Nothing to do. A ^ 1 = A
        output = _float_oper(op1)
        output.extend(_fpush())
        return output

    output = _float_oper(op1, op2)
    output.append('call __POW')
    output.extend(_fpush())
    REQUIRES.add('pow.asm')
    return output



def _ltf(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __LTF')
    output.append('push af')
    REQUIRES.add('ltf.asm')
    return output



def _gtf(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __GTF')
    output.append('push af')
    REQUIRES.add('gtf.asm')
    return output



def _lef(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __LEF')
    output.append('push af')
    REQUIRES.add('lef.asm')
    return output



def _gef(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __GEF')
    output.append('push af')
    REQUIRES.add('gef.asm')
    return output



def _eqf(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __EQF')
    output.append('push af')
    REQUIRES.add('eqf.asm')
    return output



def _nef(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __NEF')
    output.append('push af')
    REQUIRES.add('nef.asm')
    return output



def _orf(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand || 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __ORF')
    output.append('push af')
    REQUIRES.add('orf.asm')
    return output


def _xorf(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand ~~ 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __XORF')
    output.append('push af')
    REQUIRES.add('xorf.asm')
    return output



def _andf(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand && 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True. 

        Floating Point version
    '''
    op1, op2 = tuple(ins.quad[2:])
    output = _float_oper(op1, op2)
    output.append('call __ANDF')
    output.append('push af')
    REQUIRES.add('andf.asm')
    return output



def _notf(ins):
    ''' Negates top of the stack (48 bits)
    '''
    output = _float_oper(ins.quad[2])
    output.append('call __NOTF')
    output.append('push af')
    REQUIRES.add('notf.asm')
    return output



def _negf(ins):
    ''' Changes sign of top of the stack (48 bits)
    '''
    output = _float_oper(ins.quad[2])
    output.append('call __NEGF')
    output.extend(_fpush())
    REQUIRES.add('negf.asm')
    return output



def _absf(ins):
    ''' Absolute value of top of the stack (48 bits)
    '''
    output = _float_oper(ins.quad[2])
    output.append('res 7, e') # Just resets the sign bit!
    output.extend(_fpush())
    return output

