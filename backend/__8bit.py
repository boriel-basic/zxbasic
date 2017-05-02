#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains 8 bit boolean, arithmetic and
# comparation intermediate-code traductions
# --------------------------------------------------------------

from .__common import REQUIRES, is_int, is_2n, _int_ops, tmp_label


def int8(op):
    ''' Returns the operator converted to 8 bit unsigned integer.
    For signed ones, it returns the 8bit C2 (Two Complement)
    '''
    return int(op) & 0xFF


def _8bit_oper(op1, op2 = None, reversed = False):
    ''' Returns pop sequence for 8 bits operands
    1st operand in H, 2nd operand in A (accumulator)

    For some operations (like comparisons), you can swap
    operands extraction by setting reversed = True
    '''
    output = []

    if op2 is not None and reversed:
        tmp = op1
        op1 = op2
        op2 = tmp

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
            output.append('ld a, (%i)' % op)
        else:
            if op == 0:
                output.append('xor a')
            else:
                output.append('ld a, %i' % int8(op))
    else:
        if immediate:
            if indirect:
                output.append('ld a, (%s)' % op)
            else:
                output.append('ld a, %s' % op)
        elif op[0] == '_':
            if indirect:
                output.append('ld bc, (%s)' % op)  # can't use HL
                output.append('ld a, (bc)')
            else:
                output.append('ld a, (%s)' % op)
        else:
            if immediate:
                output.append('ld a, %s' % op)
            elif indirect:
                output.append('pop bc')
                output.append('ld a, (bc)')
            else:
                output.append('pop af')

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
            output.append('ld hl, (%i - 1)' % op)
        else:
            output.append('ld h, %i' % int8(op))
    else:
        if immediate:
            if indirect:
                output.append('ld hl, %s' % op)
                output.append('ld h, (hl)')
            else:
                output.append('ld h, %s' % op)
        elif op[0] == '_':
            if indirect:
                output.append('ld hl, (%s)' % op)
                output.append('ld h, (hl)' % op)
            else:
                output.append('ld hl, (%s - 1)' % op)
        else:
            output.append('pop hl')

        if indirect:
            output.append('ld b, (hl)')
            output.append('inc hl')
            output.append('ld h, (hl)')
            output.append('ld l, c')
            output.append('ld h, (hl)')

    if not reversed:
        output.extend(tmp)

    return output


def _add8(ins):
    ''' Pops last 2 bytes from the stack and adds them.
    Then push the result onto the stack.

    Optimizations:
      * If any of the operands is ZERO,
        then do NOTHING: A + 0 = 0 + A = A

      * If any of the operands is 1, then
        INC is used

      * If any of the operands is -1 (255), then
        DEC is used
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1)
        if op2 == 0:    # Nothing to add: A + 0 = A
            output.append('push af')
            return output

        op2 = int8(op2)

        if op2 == 1: # Adding 1 is just an inc
            output.append('inc a')
            output.append('push af')
            return output

        if op2 == 0xFF: # Adding 255 is just a dec
            output.append('dec a')
            output.append('push af')
            return output

        output.append('add a, %i' % int8(op2))
        output.append('push af')
        return output

    if op2[0] == '_': # stack optimization
        op1, op2 = op2, op1

    output = _8bit_oper(op1, op2)
    output.append('add a, h')
    output.append('push af')

    return output


def _sub8(ins):
    ''' Pops last 2 bytes from the stack and subtract them.
    Then push the result onto the stack. Top-1 of the stack is
    subtracted Top
    _sub8 t1, a, b === t1 <-- a - b

    Optimizations:
      * If 2nd op is ZERO,
        then do NOTHING: A - 0 = A

      * If 1st operand is 0, then
        just do a NEG

      * If any of the operands is 1, then
        DEC is used

      * If any of the operands is -1 (255), then
        INC is used
    '''

    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2): # 2nd operand
        op2 = int8(op2)
        output = _8bit_oper(op1)

        if op2 == 0:
            output.append('push af')
            return output   # A - 0 = A

        op2 = int8(op2)

        if op2 == 1:    # A - 1 == DEC A
            output.append('dec a')
            output.append('push af')
            return output

        if op2 == 0xFF: # A - (-1) == INC A
            output.append('inc a')
            output.append('push af')
            return output

        output.append('sub %i' % op2)
        output.append('push af')
        return output

    if is_int(op1): # 1st operand is numeric?
        if int8(op1) == 0: # 0 - A = -A ==> NEG A
            output = _8bit_oper(op2)
            output.append('neg')
            output.append('push af')
            return output

    # At this point, even if 1st operand is numeric, proceed
    # normally

    if op2[0] == '_': # Optimization when 2nd operand is an id
        rev = True
        op1, op2 = op2, op1
    else:
        rev = False

    output = _8bit_oper(op1, op2, rev)
    output.append('sub h')
    output.append('push af')

    return output


def _mul8(ins):
    ''' Multiplies 2 las values from the stack.

    Optimizations:
      * If any of the ops is ZERO,
        then do A = 0 ==> XOR A, cause A * 0 = 0 * A = 0

      * If any ot the ops is ONE, do NOTHING
        A * 1 = 1 * A = A
    '''

    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1)
        if op2 == 1: # A * 1 = 1 * A = A
            output.append('push af')
            return output

        if op2 == 0:
            output.append('xor a')
            output.append('push af')
            return output

        if op2 == 2: # A * 2 == A SLA 1
            output.append('add a, a')
            output.append('push af')
            return output

        if op2 == 4: # A * 4 == A SLA 2
            output.append('add a, a')
            output.append('add a, a')
            output.append('push af')
            return output

        output.append('ld h, %i' % int8(op2))
    else:
        if op2[0] == '_': # stack optimization
            op1, op2 = op2, op1

        output = _8bit_oper(op1, op2)

    output.append('call __MUL8_FAST') # Inmmediate
    output.append('push af')
    REQUIRES.add('mul8.asm')
    return output


def _divu8(ins):
    ''' Divides 2 8bit unsigned integers. The result is pushed onto the stack.

    Optimizations:
      * If 2nd op is 1 then
        do nothing

      * If 2nd op is 2 then
        Shift Right Logical
    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2):
        op2 = int8(op2)

        output = _8bit_oper(op1)
        if op2 == 1:
            output.append('push af')
            return output

        if op2 == 2:
            output.append('srl a')
            output.append('push af')
            return output

        output.append('ld h, %i' % int8(op2))
    else:
        if op2[0] == '_': # Optimization when 2nd operand is an id
            if is_int(op1) and int(op1) == 0:
                output = [] # Optimization: Discard previous op if not from the stack
                output.append('xor a')
                output.append('push af')
                return output

            rev = True
            op1, op2 = op2, op1
        else:
            rev = False

        output = _8bit_oper(op1, op2, rev)

    output.append('call __DIVU8_FAST')
    output.append('push af')
    REQUIRES.add('div8.asm')
    return output


def _divi8(ins):
    ''' Divides 2 8bit signed integers. The result is pushed onto the stack.

    Optimizations:
      * If 2nd op is 1 then
        do nothing

      * If 2nd op is 2 then
        Shift Right Arithmetic
    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2):
        op2 = int(op2) & 0xFF
        output = _8bit_oper(op1)

        if op2 == 1:
            output.append('push af')
            return output

        if op2 == -1:
            output.append('neg')
            output.append('push af')
            return output

        if op2 == 2:
            output.append('sra a')
            output.append('push af')
            return output

        output.append('ld h, %i' % int8(op2))
    else:
        if op2[0] == '_': # Optimization when 2nd operand is an id
            if is_int(op1) and int(op1) == 0:
                output = [] # Optimization: Discard previous op if not from the stack
                output.append('xor a')
                output.append('push af')
                return output
    
            rev = True
            op1, op2 = op2, op1
        else:
            rev = False

        output = _8bit_oper(op1, op2, rev)

    output.append('call __DIVI8_FAST')
    output.append('push af')
    REQUIRES.add('div8.asm')
    return output


def _modu8(ins):
    ''' Reminder of div. 2 8bit unsigned integers. The result is pushed onto the stack.

    Optimizations:
      * If 2nd operands is 1 then
        returns 0

      * If 2nd operand = 2^n => do AND (2^n - 1)

    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2):
        op2 = int8(op2)

        output = _8bit_oper(op1)
        if op2 == 1:
            if op1[0] == '_':
                output = [] # Optimization: Discard previous op if not from the stack

            output.append('xor a')
            output.append('push af')
            return output

        if is_2n(op2):
            output.append('and %i' % (op2 - 1))
            output.append('push af')
            return output

        output.append('ld h, %i' % int8(op2))
    else:
        if op2[0] == '_': # Optimization when 2nd operand is an id
            if is_int(op1) and int(op1) == 0:
                output = [] # Optimization: Discard previous op if not from the stack
                output.append('xor a')
                output.append('push af')
                return output

            rev = True
            op1, op2 = op2, op1
        else:
            rev = False

        output = _8bit_oper(op1, op2, rev)

    output.append('call __MODU8_FAST')
    output.append('push af')
    REQUIRES.add('div8.asm')
    return output


def _modi8(ins):
    ''' Reminder of div. 2 8bit unsigned integers. The result is pushed onto the stack.

    Optimizations:
      * If 2nd operands is 1 then
        returns 0

      * If 2nd operand = 2^n => do AND (2^n - 1)

    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2):
        op2 = int8(op2)

        output = _8bit_oper(op1)
        if op2 == 1:
            if op1[0] == '_':
                output = [] # Optimization: Discard previous op if not from the stack

            output.append('xor a')
            output.append('push af')
            return output

        if is_2n(op2):
            output.append('and %i' % (op2 - 1))
            output.append('push af')
            return output

        output.append('ld h, %i' % int8(op2))
    else:
        if op2[0] == '_': # Optimization when 2nd operand is an id
            if is_int(op1) and int(op1) == 0:
                output = [] # Optimization: Discard previous op if not from the stack
                output.append('xor a')
                output.append('push af')
                return output

            rev = True
            op1, op2 = op2, op1
        else:
            rev = False

        output = _8bit_oper(op1, op2, rev)

    output.append('call __MODI8_FAST')
    output.append('push af')
    REQUIRES.add('div8.asm')
    return output


def _ltu8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit unsigned version
    '''
    output = _8bit_oper(ins.quad[2], ins.quad[3])
    output.append('cp h')
    output.append('sbc a, a')
    output.append('push af')

    return output


def _lti8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand < 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit signed version
    '''
    output = []
    output.extend(_8bit_oper(ins.quad[2], ins.quad[3]))
    output.append('call __LTI8')
    output.append('push af')
    REQUIRES.add('lti8.asm')

    return output


def _gtu8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit unsigned version
    '''
    output = _8bit_oper(ins.quad[2], ins.quad[3], reversed = True)
    output.append('cp h')
    output.append('sbc a, a')
    output.append('push af')

    return output


def _gti8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand > 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit signed version
    '''
    output = _8bit_oper(ins.quad[2], ins.quad[3], reversed = True)
    output.append('call __LTI8')
    output.append('push af')
    REQUIRES.add('lti8.asm')

    return output


def _eq8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand == 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit un/signed version
    '''
    if is_int(ins.quad[3]):
        output = _8bit_oper(ins.quad[2])
        n = int8(ins.quad[3])
        if n:
            if n == 1:
                output.append('dec a')
            else:
                output.append('sub %i' % n)
    else:
        output = _8bit_oper(ins.quad[2], ins.quad[3])
        output.append('sub h')

    output.append('sub 1') # Sets Carry only if 0
    output.append('sbc a, a')
    output.append('push af')

    return output


def _leu8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit unsigned version
    '''
    output = _8bit_oper(ins.quad[2], ins.quad[3], reversed = True)
    output.append('sub h') # Carry if H > A
    output.append('ccf')   # Negates => Carry if H <= A
    output.append('sbc a, a')
    output.append('push af')

    return output


def _lei8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand <= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit signed version
    '''
    output = _8bit_oper(ins.quad[2], ins.quad[3])
    output.append('call __LEI8')
    output.append('push af')
    REQUIRES.add('lei8.asm')

    return output


def _geu8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit unsigned version
    '''
    if is_int(ins.quad[3]):
        output = _8bit_oper(ins.quad[2])
        n = int8(ins.quad[3])
        if n:
            output.append('sub %i' % n)
        else:
            output.append('cp a')
    else:
        output = _8bit_oper(ins.quad[2], ins.quad[3])
        output.append('sub h')

    output.append('ccf')
    output.append('sbc a, a')
    output.append('push af')

    return output


def _gei8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand >= 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit signed version
    '''
    output = _8bit_oper(ins.quad[2], ins.quad[3], reversed = True)
    output.append('call __LEI8')
    output.append('push af')
    REQUIRES.add('lei8.asm')

    return output


def _ne8(ins):
    ''' Compares & pops top 2 operands out of the stack, and checks
        if the 1st operand != 2nd operand (top of the stack).
        Pushes 0 if False, 1 if True.

        8 bit un/signed version
    '''
    if is_int(ins.quad[3]):
        output = _8bit_oper(ins.quad[2])
        n = int8(ins.quad[3])
        if n:
            if n == 1:
                output.append('dec a')
            else:
                output.append('sub %i' % int8(ins.quad[3]))
    else:
        output = _8bit_oper(ins.quad[2], ins.quad[3])
        output.append('sub h')

    output.append('push af')

    return output


def _or8(ins):
    ''' Pops top 2 operands out of the stack, and checks
        if 1st operand OR (logical) 2nd operand (top of the stack),
        pushes 0 if False, not 0 if True.

        8 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1)
        if op2 == 0:    # X or False = X
            output.append('push af')
            return output

        # X or True = True
        output.append('ld a, 1')    # True
        output.append('push af')
        return output

    output = _8bit_oper(op1, op2)
    output.append('or h')
    output.append('push af')

    return output


def _bor8(ins):
    ''' pops top 2 operands out of the stack, and does
        OR (bitwise) with 1st and 2nd operand (top of the stack),
        pushes result.

        8 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1)
        if op2 == 0:    # X | 0 = X
            output.append('push af')
            return output

        if op2 == 0xFF: # X | 0xFF = 0xFF
            output.append('ld a, 0FFh')
            output.append('push af')
            return output

        op1, op2 = tuple(ins.quad[2:])

    output = _8bit_oper(op1, op2)
    output.append('or h')
    output.append('push af')

    return output


def _and8(ins):
    ''' Pops top 2 operands out of the stack, and checks
        if 1st operand AND (logical) 2nd operand (top of the stack),
        pushes 0 if False, not 0 if True.

        8 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1) # Pops the stack (if applicable)
        if op2 != 0:    # X and True = X
            output.append('push af')
            return output
    
        # False and X = False
        output.append('xor a')
        output.append('push af')
        return output

    output = _8bit_oper(op1, op2)
    output.append('call __AND8')
    output.append('push af')
    REQUIRES.add('and8.asm')

    return output


def _band8(ins):
    ''' Pops top 2 operands out of the stack, and does
        1st AND (bitwise) 2nd operand (top of the stack),
        pushes the result.

        8 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1) 
        if op2 == 0xFF: # X & 0xFF = X
            output.append('push af')
            return output

        if op2 == 0:    # X and 0 = 0
            output.append('xor a')
            output.append('push af')
            return output

        op1, op2 = tuple(ins.quad[2:])

    output = _8bit_oper(op1, op2)
    output.append('and h')
    output.append('push af')
    REQUIRES.add('and8.asm')

    return output


def _xor8(ins):
    ''' Pops top 2 operands out of the stack, and checks
        if 1st operand XOR (logical) 2nd operand (top of the stack),
        pushes 0 if False, 1 if True.

        8 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1)    # True or X = not X
        if op2 == 0:    # False xor X = X
            output.append('push af')
            return output

        output.append('sub 1')
        output.append('sbc a, a')
        output.append('push af')
        return output

    output = _8bit_oper(op1, op2)
    output.append('call __XOR8')
    output.append('push af')
    REQUIRES.add('xor8.asm')

    return output


def _bxor8(ins):
    ''' Pops top 2 operands out of the stack, and does
        1st operand XOR (bitwise) 2nd operand (top of the stack),
        pushes the result

        8 bit un/signed version
    '''
    op1, op2 = tuple(ins.quad[2:])
    if _int_ops(op1, op2) is not None:
        op1, op2 = _int_ops(op1, op2)

        output = _8bit_oper(op1) 
        if op2 == 0:    # 0 xor X = X
            output.append('push af')
            return output

        if op2 == 0xFF: # X xor 0xFF = ~X
            output.append('cpl')
            output.append('push af')
            return output

        op1, op2 = tuple(ins.quad[2:])

    output = _8bit_oper(op1, op2)
    output.append('xor h')
    output.append('push af')

    return output


def _not8(ins):
    ''' Negates (Logical NOT) top of the stack (8 bits in AF)
    '''
    output = _8bit_oper(ins.quad[2])
    output.append('sub 1') # Gives carry only if A = 0
    output.append('sbc a, a') # Gives FF only if Carry else 0
    output.append('push af')

    return output


def _bnot8(ins):
    ''' Negates (BITWISE NOT) top of the stack (8 bits in AF)
    '''
    output = _8bit_oper(ins.quad[2])
    output.append('cpl') # Gives carry only if A = 0
    output.append('push af')

    return output


def _neg8(ins):
    ''' Negates top of the stack (8 bits in AF)
    '''
    output = _8bit_oper(ins.quad[2])
    output.append('neg')
    output.append('push af')

    return output


def _abs8(ins):
    ''' Absolute value of top of the stack (8 bits in AF)
    '''
    output = _8bit_oper(ins.quad[2])
    output.append('call __ABS8')
    output.append('push af')
    REQUIRES.add('abs8.asm')
    return output


def _shru8(ins):
    ''' Shift 8bit unsigned integer to the right. The result is pushed onto the stack.

    Optimizations:
      * If 1nd or 2nd op is 0 then
        do nothing

      * If 2nd op is < 4 then
        unroll loop
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        op2 = int8(op2)

        output = _8bit_oper(op1)
        if op2 == 0:
            output.append('push af')
            return output

        if op2 < 4:
            output.extend(['srl a'] * op2)
            output.append('push af')
            return output

        label = tmp_label()
        output.append('ld b, %i' % int8(op2))
        output.append('%s:' % label)
        output.append('srl a')
        output.append('djnz %s' % label)
        output.append('push af')
        return output

    if is_int(op1) and int(op1) == 0:
        output = _8bit_oper(op2)
        output.append('xor a')
        output.append('push af')
        return output

    output = _8bit_oper(op1, op2, True)
    label = tmp_label()
    label2 = tmp_label()
    output.append('or a')
    output.append('ld b, a')
    output.append('ld a, h')
    output.append('jr z, %s' % label2)
    output.append('%s:' % label)
    output.append('srl a')
    output.append('djnz %s' % label)
    output.append('%s:' % label2)
    output.append('push af')
    return output



def _shri8(ins):
    ''' Shift 8bit signed integer to the right. The result is pushed onto the stack.

    Optimizations:
      * If 1nd or 2nd op is 0 then
        do nothing

      * If 2nd op is < 4 then
        unroll loop
    '''
    op1, op2 = tuple(ins.quad[2:])

    if is_int(op2):
        op2 = int8(op2)

        output = _8bit_oper(op1)
        if op2 == 0:
            output.append('push af')
            return output

        if op2 < 4:
            output.extend(['sra a'] * op2)
            output.append('push af')
            return output

        label = tmp_label()
        output.append('ld b, %i' % int8(op2))
        output.append('%s:' % label)
        output.append('sra a')
        output.append('djnz %s' % label)
        output.append('push af')
        return output

    if is_int(op1) and int(op1) == 0:
        output = _8bit_oper(op2)
        output.append('xor a')
        output.append('push af')
        return output

    output = _8bit_oper(op1, op2, True)
    label = tmp_label()
    label2 = tmp_label()
    output.append('or a')
    output.append('ld b, a')
    output.append('ld a, h')
    output.append('jr z, %s' % label2)    
    output.append('%s:' % label)
    output.append('sra a')
    output.append('djnz %s' % label)
    output.append('%s:' % label2)
    output.append('push af')
    return output


def _shl8(ins):
    ''' Shift 8bit (un)signed integer to the left. The result is pushed onto the stack.

    Optimizations:
      * If 1nd or 2nd op is 0 then
        do nothing

      * If 2nd op is < 4 then
        unroll loop
    '''
    op1, op2 = tuple(ins.quad[2:])
    if is_int(op2):
        op2 = int8(op2)

        output = _8bit_oper(op1)
        if op2 == 0:
            output.append('push af')
            return output

        if op2 < 6:
            output.extend(['add a, a'] * op2)
            output.append('push af')
            return output

        label = tmp_label()
        output.append('ld b, %i' % int8(op2))
        output.append('%s:' % label)
        output.append('add a, a')
        output.append('djnz %s' % label)
        output.append('push af')
        return output

    if is_int(op1) and int(op1) == 0:
        output = _8bit_oper(op2)
        output.append('xor a')
        output.append('push af')
        return output

    output = _8bit_oper(op1, op2, True)
    label = tmp_label()
    label2 = tmp_label()
    output.append('or a')
    output.append('ld b, a')
    output.append('ld a, h')
    output.append('jr z, %s' % label2)
    output.append('%s:' % label)
    output.append('add a, a')
    output.append('djnz %s' % label)
    output.append('%s:' % label2)
    output.append('push af')
    return output



