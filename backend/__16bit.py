#!/usr/bin/python
# -*- coding: utf-8 -*-

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 8 bit boolean, arithmetic and
# comparation intermediate-code traductions
# --------------------------------------------------------------

from .__common import REQUIRES, is_int, log2, is_2n, _int_ops, tmp_label
from .__8bit import _8bit_oper


# -----------------------------------------------------
# 16 bits operands
# -----------------------------------------------------
def int16(op):
    ''' Returns a 16 bit operand converted to 16 bits unsigned int.
    Negative numbers are returned in 2 complement.
    '''
    return int(op) & 0xFFFF


def _16bit_oper(op1, op2 = None, reversed = False):
    ''' Returns pop sequence for 16 bits operands
    1st operand in HL, 2nd operand in DE

    For subtraction, division, etc. you can swap operators extraction order
    by setting reversed to True
    '''
    output = []

    if op1 is not None:
        op1 = str(op1) # always to str

    if op2 is not None:
        op2 = str(op2) # always to str

    if op2 is not None and reversed:
        op1, op2 = op2, op1

    op = op1
    indirect = (op[0] == '*')
    if indirect:
        op = op[1:]

    immediate = (op[0] == '#')
    if immediate:
        op = op[1:]

    if is_int(op):
        op = int(op)

        if indirect:
            output.append('ld hl, (%i)' % op)
        else:
            output.append('ld hl, %i' % int16(op))
    else:
        if immediate:
            if indirect:
                output.append('ld hl, (%s)' % op)
            else:
                output.append('ld hl, %s' % op)
        else:
            if op[0] == '_':
                output.append('ld hl, (%s)' % op)
            else:
                output.append('pop hl')
    
            if indirect:
                output.append('ld a, (hl)')
                output.append('inc hl')
                output.append('ld h, (hl)')
                output.append('ld l, a')

    if op2 is None:
        return output

    if not reversed:
        tmp = output
        output = []

    op = op2
    indirect = (op[0] == '*')
    if indirect:
        op = op[1:]

    immediate = (op[0] == '#')
    if immediate:
        op = op[1:]

    if is_int(op):
        op = int(op)

        if indirect:
            output.append('ld de, (%i)' % op)
        else:
            output.append('ld de, %i' % int16(op))
    else:
        if immediate:
            output.append('ld de, %s' % op)
        else:
            if op[0] == '_':
                output.append('ld de, (%s)' % op)
            else:
                output.append('pop de')
    
            if indirect:
                output.append('call __LOAD_DE_DE') # DE = (DE)
                REQUIRES.add('lddede.asm')

    if not reversed:
        output.extend(tmp)

    return output



# -----------------------------------------------------
#               Arithmetic operations
# -----------------------------------------------------

def _add16(ins):
    ''' Pops last 2 bytes from the stack and adds them.
    Then push the result onto the stack.


    Optimizations:
      * If any of the operands is ZERO,
        then do NOTHING: A + 0 = 0 + A = A

      * If any of the operands is < 4, then
        INC is used

      * If any of the operands is > (65531) (-4), then
        DEC is used
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)
        op2 = int16(op2)
        output = _16bit_oper(op1)

        if op2 == 0:
            output.append('push hl')
            return output # ADD HL, 0 => NOTHING

        if op2 < 4:
            output.extend(['inc hl'] * op2) #  ADD HL, 2 ==> inc hl; inc hl
            output.append('push hl')
            return output

        if op2 > 65531: # (between -4 and 0)
            output.extend(['dec hl'] * (0x10000 - op2))
            output.append('push hl')
            return output

        output.append('ld de, %i' % op2)
        output.append('add hl, de')
        output.append('push hl')
        return output

    if op2[0] == '_': # stack optimization
        op1, op2 = op2, op1
    
    output = _16bit_oper(op1, op2)
    output.append('add hl, de')
    output.append('push hl')
    return output


def _sub16(ins):
    ''' Pops last 2 words from the stack and subtract them.
    Then push the result onto the stack. Top of the stack is
    subtracted Top -1

    Optimizations:
      * If 2nd op is ZERO,
        then do NOTHING: A - 0 = A

      * If any of the operands is < 4, then
        DEC is used

      * If any of the operands is > 65531 (-4..-1), then
        INC is used
    '''
    op1, op2 = tuple(ins.quad[2:4])

    if is_int(op2):
        op = int16(op2)
        output = _16bit_oper(op1)

        if op == 0:
            output.append('push hl')
            return output

        if op < 4:
            output.extend(['dec hl'] * op)
            output.append('push hl')
            return output

        if op > 65531:
            output.extend(['inc hl'] * (0x10000 - op))
            output.append('push hl')
            return output

        output.append('ld de, -%i' % op)
        output.append('add hl, de')
        output.append('push hl')
        return output

    if op2[0] == '_': # Optimization when 2nd operand is an id
        rev = True
        op1, op2 = op2, op1
    else:
        rev = False

    output = _16bit_oper(op1, op2, rev)
    output.append('or a')
    output.append('sbc hl, de')
    output.append('push hl')
    return output



def _mul16(ins):
    ''' Multiplies tow last 16bit values on top of the stack and
    and returns the value on top of the stack

    Optimizations:
      * If any of the ops is ZERO,
        then do A = 0 ==> XOR A, cause A * 0 = 0 * A = 0

      * If any ot the ops is ONE, do NOTHING
        A * 1 = 1 * A = A

      * If B is 2^n and B < 16 => Shift Right n
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:   # If any of the operands is constant
        op1, op2 = _int_ops(op1, op2)    # put the constant one the 2nd
        output = _16bit_oper(op1)

        if op2 == 0: # A * 0 = 0 * A = 0
            if op1[0] in ('_', '$'):
                output = [] # Optimization: Discard previous op if not from the stack
            output.append('ld hl, 0')
            output.append('push hl')
            return output

        if op2 == 1: # A * 1 = 1 * A == A => Do nothing
            output.append('push hl')
            return output 

        if op2 == 0xFFFF: # This is the same as (-1)
            output.append('call __NEGHL')
            output.append('push hl')
            REQUIRES.add('neg16.asm')
            return output

        if is_2n(op2) and log2(op2) < 4:
            output.extend(['add hl, hl'] * int(log2(op2)))
            output.append('push hl')
            return output

        output.append('ld de, %i' % op2)
    else:
        if op2[0] == '_': # stack optimization
            op1, op2 = op2, op1

        output = _16bit_oper(op1, op2)

    output.append('call __MUL16_FAST') # Inmmediate
    output.append('push hl')
    REQUIRES.add('mul16.asm')
    return output



def _divu16(ins):
    ''' Divides 2 16bit unsigned integers. The result is pushed onto the stack.

    Optimizations:
      * If 2nd op is 1 then
        do nothing

      * If 2nd op is 2 then
        Shift Right Logical
    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op1) and int(op1) == 0: # 0 / A = 0

            if op2[0] in ('_', '$'):
                output = [] # Optimization: Discard previous op if not from the stack
            else:
                output = _16bit_oper(op2) # Normalize stack

            output.append('ld hl, 0')
            output.append('push hl')
            return output

    if is_int(op2):
        op = int16(op2)
        output = _16bit_oper(op1)

        if op2 == 0: # A * 0 = 0 * A = 0
            if op1[0] in ('_', '$'):
                output = [] # Optimization: Discard previous op if not from the stack
            output.append('ld hl, 0')
            output.append('push hl')
            return output

        if op == 1:
            output.append('push hl')
            return output

        if op == 2:
            output.append('srl h')
            output.append('rr l')
            output.append('push hl')
            return output

        output.append('ld de, %i' % op)
    else:
        if op2[0] == '_': # Optimization when 2nd operand is an id
            rev = True
            op1, op2 = op2, op1
        else:
            rev = False
        output = _16bit_oper(op1, op2, rev)

    output.append('call __DIVU16')
    output.append('push hl')
    REQUIRES.add('div16.asm')
    return output



def _divi16(ins):
    ''' Divides 2 16bit signed integers. The result is pushed onto the stack.

    Optimizations:
      * If 2nd op is 1 then
        do nothing

      * If 2nd op is -1 then
        do NEG

      * If 2nd op is 2 then
        Shift Right Arithmetic
    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op1) and int(op1) == 0: # 0 / A = 0

            if op2[0] in ('_', '$'):
                output = [] # Optimization: Discard previous op if not from the stack
            else:
                output = _16bit_oper(op2) # Normalize stack

            output.append('ld hl, 0')
            output.append('push hl')
            return output

    if is_int(op2):
        op = int16(op2)
        output = _16bit_oper(op1)

        if op == 1:
            output.append('push hl')
            return output

        if op == -1:
            output.append('call __NEGHL')
            output.append('push hl')
            REQUIRES.add('neg16.asm')
            return output

        if op == 2:
            output.append('sra h')
            output.append('rr l')
            output.append('push hl')
            return output

        output.append('ld de, %i' % op)
    else:
        if op2[0] == '_': # Optimization when 2nd operand is an id
            rev = True
            op1, op2 = op2, op1
        else:
            rev = False
        output = _16bit_oper(op1, op2, rev)

    output.append('call __DIVI16')
    output.append('push hl')
    REQUIRES.add('div16.asm')
    return output



def _modu16(ins):
    ''' Reminder of div. 2 16bit unsigned integers. The result is pushed onto the stack.

        Optimizations:
         * If 2nd operand is 1 => Return 0
         * If 2nd operand = 2^n => do AND (2^n - 1)
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        op2 = int16(op2)
        output = _16bit_oper(op1)

        if op2 == 1:
            if op2[0] in ('_', '$'):
                output = [] # Optimization: Discard previous op if not from the stack

            output.append('ld hl, 0')
            output.append('push hl')
            return output

        if is_2n(op2):
            k = op2 - 1
            if op2 > 255: # only affects H
                output.append('ld a, h')
                output.append('and %i' % (k >> 8))
                output.append('ld h, a')
            else:
                output.append('ld h, 0') # High part goes 0
                output.append('ld a, l')
                output.append('and %i' % (k % 0xFF))
                output.append('ld l, a')

            output.append('push hl')
            return output

        output.append('ld de, %i' % op2)
    else:
        output = _16bit_oper(op1, op2)

    output.append('call __MODU16')
    output.append('push hl')
    REQUIRES.add('div16.asm')
    return output


def _modi16(ins):
    ''' Reminder of div 2 16bit signed integers. The result is pushed onto the stack.

        Optimizations:
         * If 2nd operand is 1 => Return 0
         * If 2nd operand = 2^n => do AND (2^n - 1)
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        op2 = int16(op2)
        output = _16bit_oper(op1)

        if op2 == 1:
            if op2[0] in ('_', '$'):
                output = [] # Optimization: Discard previous op if not from the stack

            output.append('ld hl, 0')
            output.append('push hl')
            return output

        if is_2n(op2):
            k = op2 - 1
            if op2 > 255: # only affects H
                output.append('ld a, h')
                output.append('and %i' % (k >> 8))
                output.append('ld h, a')
            else:
                output.append('ld h, 0') # High part goes 0
                output.append('ld a, l')
                output.append('and %i' % (k % 0xFF))
                output.append('ld l, a')

            output.append('push hl')
            return output

        output.append('ld de, %i' % op2)
    else:
        output = _16bit_oper(op1, op2)

    output.append('call __MODI16')
    output.append('push hl')
    REQUIRES.add('div16.asm')
    return output


def _ltu16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit unsigned version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3])
    output.append('or a')
    output.append('sbc hl, de')
    output.append('sbc a, a')
    output.append('push af')
    return output



def _lti16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit signed version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3])
    output.append('call __LTI16')
    output.append('push af')
    REQUIRES.add('lti16.asm')
    return output



def _gtu16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit unsigned version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3], reversed = True)
    output.append('or a')
    output.append('sbc hl, de')
    output.append('sbc a, a')
    output.append('push af')
    return output



def _gti16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit signed version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3], reversed = True)
    output.append('call __LTI16')
    output.append('push af')
    REQUIRES.add('lti16.asm')
    return output


def _leu16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit unsigned version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3], reversed = True)
    output.append('or a')
    output.append('sbc hl, de') # Carry if A > B
    output.append('ccf')  # Negates the result => Carry if A <= B
    output.append('sbc a, a')
    output.append('push af')
    return output


def _lei16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit signed version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3])
    output.append('call __LEI16')
    output.append('push af')
    REQUIRES.add('lei16.asm')
    return output


def _geu16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit unsigned version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3])
    output.append('or a')
    output.append('sbc hl, de')
    output.append('ccf')
    output.append('sbc a, a')
    output.append('push af')
    return output



def _gei16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit signed version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3], reversed = True)
    output.append('call __LEI16')
    output.append('push af')
    REQUIRES.add('lei16.asm')
    return output



def _eq16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit un/signed version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3])
    output.append('call __EQ16')
    output.append('push af')
    REQUIRES.add('eq16.asm')

    return output



def _ne16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        16 bit un/signed version
    '''
    output = _16bit_oper(ins.quad[2], ins.quad[3])
    output.append('or a') # Resets carry flag
    output.append('sbc hl, de')
    output.append('ld a, h')
    output.append('or l')
    output.append('push af')

    return output



def _or16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand OR (logical) 2nd operand (top of the stack),
        pushes 0 if False, 1 if True.

        16 bit un/signed version

        Optimizations:

        If any of the operators are constants: Returns either 0 or
        the other operand
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        if op2 == 0:
            output = _16bit_oper(op1)
            output.append('ld a, h')
            output.append('or l') # Convert x to Boolean
            output.append('push af')
            return output # X or False = X

        output = _16bit_oper(op1)
        output.append('ld a, 0FFh') # X or True = True
        output.append('push af')
        return output

    output = _16bit_oper(ins.quad[2], ins.quad[3])
    output.append('ld a, h')
    output.append('or l')
    output.append('or d')
    output.append('or e')
    output.append('push af')
    return output


def _bor16(ins):
    ''' Pops top 2 operands out of the stack, and performs
        1st operand OR (bitwise) 2nd operand (top of the stack),
        pushes result (16 bit in HL).

        16 bit un/signed version

        Optimizations:

        If any of the operators are constants: Returns either 0 or
        the other operand
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _16bit_oper(op1)
        if op2 == 0: # X | 0 = X
            output.append('push hl')
            return output

        if op2 == 0xFFFF: # X & 0xFFFF = 0xFFFF
            output.append('ld hl, 0FFFFh')
            output.append('push hl')
            return output

    output = _16bit_oper(op1, op2)
    output.append('call __BOR16')
    output.append('push hl')
    REQUIRES.add('bor16.asm')
    return output



def _xor16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand XOR (logical) 2nd operand (top of the stack),
        pushes 0 if False, 1 if True.

        16 bit un/signed version

        Optimizations:

        If any of the operators are constants: Returns either 0 or
        the other operand
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)
        output = _16bit_oper(op1)

        if op2 == 0: # X xor False = X 
            output.append('ld a, h')
            output.append('or l')
            output.append('push af')
            return output 

        # X xor True = NOT X
        output.append('ld a, h')
        output.append('or l')
        output.append('sub 1')
        output.append('sbc a, a')
        output.append('push af')
        return output

    output = _16bit_oper(ins.quad[2], ins.quad[3])
    output.append('call __XOR16')
    output.append('push af')
    REQUIRES.add('xor16.asm')
    return output



def _bxor16(ins):
    ''' Pops top 2 operands out of the stack, and performs
        1st operand XOR (bitwise) 2nd operand (top of the stack),
        pushes result (16 bit in HL).

        16 bit un/signed version

        Optimizations:

        If any of the operators are constants: Returns either 0 or
        the other operand
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _16bit_oper(op1)
        if op2 == 0: # X ^ 0 = X
            output.append('push hl')
            return output

        if op2 == 0xFFFF: # X ^ 0xFFFF = bNOT X
            output.append('call __NEGHL')
            output.append('push hl')
            REQUIRES.add('neg16.asm')
            return output

    output = _16bit_oper(op1, op2)
    output.append('call __BXOR16')
    output.append('push hl')
    REQUIRES.add('bxor16.asm')
    return output


def _and16(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand AND (logical) 2nd operand (top of the stack),
        pushes 0 if False, 1 if True.

        16 bit un/signed version

        Optimizations:

        If any of the operators are constants: Returns either 0 or
        the other operand
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _16bit_oper(op1)
        if op2 != 0:
            output.append('ld a, h')
            output.append('or l')
            output.append('push af')
            return output # X and True = X

        output = _16bit_oper(op1)
        output.append('xor a') # X and False = False
        output.append('push af')
        return output

    output = _16bit_oper(op1, op2)
    output.append('call __AND16')
    output.append('push af')
    REQUIRES.add('and16.asm')
    return output


def _band16(ins):
    ''' Pops top 2 operands out of the stack, and performs
        1st operand AND (bitwise) 2nd operand (top of the stack),
        pushes result (16 bit in HL).

        16 bit un/signed version

        Optimizations:

        If any of the operators are constants: Returns either 0 or
        the other operand
    '''
    op1, op2 = tuple(ins.quad[2:])

    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        if op2 == 0xFFFF: # X & 0xFFFF = X
            return []

        if op2 == 0: # X & 0 = 0
            output = _16bit_oper(op1)
            output.append('ld hl, 0')
            output.append('push hl')
            return output

    output = _16bit_oper(op1, op2)
    output.append('call __BAND16')
    output.append('push hl')
    REQUIRES.add('band16.asm')
    return output


def _not16(ins):
    ''' Negates top (Logical NOT) of the stack (16 bits in HL)
    '''
    output = _16bit_oper(ins.quad[2])
    output.append('ld a, h')
    output.append('or l')
    output.append('sub 1')
    output.append('sbc a, a')
    output.append('push af')
    return output


def _bnot16(ins):
    ''' Negates top (Bitwise NOT) of the stack (16 bits in HL)
    '''
    output = _16bit_oper(ins.quad[2])
    output.append('call __BNOT16')
    output.append('push hl')
    REQUIRES.add('bnot16.asm')
    return output


def _neg16(ins):
    ''' Negates top of the stack (16 bits in HL)
    '''
    output = _16bit_oper(ins.quad[2])
    output.append('call __NEGHL')
    output.append('push hl')
    REQUIRES.add('neg16.asm')
    return output


def _abs16(ins):
    ''' Absolute value of top of the stack (16 bits in HL)
    '''
    output = _16bit_oper(ins.quad[2])
    output.append('call __ABS16')
    output.append('push hl')
    REQUIRES.add('abs16.asm')
    return output


def _shru16(ins):
    ''' Logical right shift 16bit unsigned integer.
    The result is pushed onto the stack.

    Optimizations:
      * If 2nd op is 0 then
        do nothing

      * If 2nd op is 1
        Shift Right Arithmetic
    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2):
        op = int16(op2)
        if op == 0:
            return []

        output = _16bit_oper(op1)
        if op == 1:
            output.append('srl h')
            output.append('rr l')
            output.append('push hl')
            return output

        output.append('ld b, %i' % op)
    else:
        output = _8bit_oper(op2)
        output.append('ld b, a')
        output.extend(_16bit_oper(op1))

    label = tmp_label()
    output.append('%s:' % label)
    output.append('srl h')
    output.append('rr l')
    output.append('djnz %s' % label)
    output.append('push hl')
    return output


def _shri16(ins):
    ''' Arithmetical right shift 16bit signed integer.
    The result is pushed onto the stack.

    Optimizations:
      * If 2nd op is 0 then
        do nothing

      * If 2nd op is 1
        Shift Right Arithmetic
    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2):
        op = int16(op2)
        if op == 0:
            return []

        output = _16bit_oper(op1)
        if op == 1:
            output.append('srl h')
            output.append('rr l')
            output.append('push hl')
            return output

        output.append('ld b, %i' % op)
    else:
        output = _8bit_oper(op2)
        output.append('ld b, a')
        output.extend(_16bit_oper(op1))

    label = tmp_label()
    output.append('%s:' % label)
    output.append('sra h')
    output.append('rr l')
    output.append('djnz %s' % label)
    output.append('push hl')
    return output


def _shl16(ins):
    ''' Logical/aritmetical left shift 16bit (un)signed integer.
    The result is pushed onto the stack.

    Optimizations:
      * If 2nd op is 0 then
        do nothing

      * If 2nd op is lower than 6
        unroll lop
    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2):
        op = int16(op2)
        if op == 0:
            return []

        output = _16bit_oper(op1)
        if op < 6:
            output.extend(['add hl, hl'] * op)
            output.append('push hl')
            return output

        output.append('ld b, %i' % op)
    else:
        output = _8bit_oper(op2)
        output.append('ld b, a')
        output.extend(_16bit_oper(op1))

    label = tmp_label()
    output.append('%s:' % label)
    output.append('add hl, hl')
    output.append('djnz %s' % label)
    output.append('push hl')
    return output

