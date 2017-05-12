#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains string arithmetic and
# comparation intermediate-code traductions
# --------------------------------------------------------------

from .__common import REQUIRES


def _str_oper(op1, op2=None, reversed=False, no_exaf=False):
    ''' Returns pop sequence for 16 bits operands
    1st operand in HL, 2nd operand in DE

    You can swap operators extraction order
    by setting reversed to True.

    If no_exaf = True => No bits flags in A' will be used.
                        This saves two bytes.
    '''
    output = []

    if op2 is not None and reversed:
        op1, op2 = op2, op1

    tmp2 = False
    if op2 is not None:
        val = op2
        if val[0] == '*':
            indirect = True
            val = val[1:]
        else:
            indirect = False

        if val[0] == '_':  # Direct
            output.append('ld de, (%s)' % val)
        elif val[0] == '#':  # Direct
            output.append('ld de, %s' % val[1:])
        elif val[0] == '$':  # Direct in the stack
            output.append('pop de')
        else:
            output.append('pop de')
            tmp2 = True

        if indirect:
            output.append('call __LOAD_DE_DE')
            REQUIRES.add('lddede.asm')  # TODO: This is never used??

    if reversed:
        tmp = output
        output = []

    val = op1
    tmp1 = False
    if val[0] == '*':
        indirect = True
        val = val[1:]
    else:
        indirect = False

    if val[0] == '_':  # Direct
        output.append('ld hl, (%s)' % val)
    elif val[0] == '#':  # Inmmediate
        output.append('ld hl, %s' % val[1:])
    elif val[0] == '$':  # Direct in the stack
        output.append('pop hl')
    else:
        output.append('pop hl')
        tmp1 = True

    if indirect:
        output.append('ld hl, %s' % val[1:])
        output.append('ld c, (hl)')
        output.append('inc hl')
        output.append('ld h, (hl)')
        output.append('ld l, c')

    if reversed:
        output.extend(tmp)

    if not no_exaf:
        if tmp1 and tmp2:
            output.append('ld a, 3')  # Marks both strings to be freed
        elif tmp1:
            output.append('ld a, 1')  # Marks str1 to be freed
        elif tmp2:
            output.append('ld a, 2')  # Marks str2 to be freed
        else:
            output.append('xor a')  # Marks no string to be freed

    if op2 is not None:
        return (tmp1, tmp2, output)

    return (tmp1, output)


def _free_sequence(tmp1, tmp2=False):
    ''' Outputs a FREEMEM sequence for 1 or 2 ops
    '''
    if not tmp1 and not tmp2:
        return []

    output = []
    if tmp1 and tmp2:
        output.append('pop de')
        output.append('ex (sp), hl')
        output.append('push de')
        output.append('call __MEM_FREE')
        output.append('pop hl')
        output.append('call __MEM_FREE')
    else:
        output.append('ex (sp), hl')
        output.append('call __MEM_FREE')

    output.append('pop hl')
    REQUIRES.add('alloc.asm')
    return output


def _addstr(ins):
    ''' Adds 2 string values. The result is pushed onto the stack.
    Note: This instruction does admit direct strings (as labels).
    '''
    (tmp1, tmp2, output) = _str_oper(ins.quad[2], ins.quad[3], no_exaf=True)

    if tmp1:
        output.append('push hl')

    if tmp2:
        output.append('push de')

    output.append('call __ADDSTR')
    output.extend(_free_sequence(tmp1, tmp2))
    output.append('push hl')
    REQUIRES.add('strcat.asm')
    return output


def _ltstr(ins):
    ''' Compares & pops top 2 strings out of the stack.
    Temporal values are freed from memory. (a$ < b$)
    '''
    (tmp1, tmp2, output) = _str_oper(ins.quad[2], ins.quad[3])
    output.append('call __STRLT')
    output.append('push af')
    REQUIRES.add('string.asm')
    return output


def _gtstr(ins):
    ''' Compares & pops top 2 strings out of the stack.
    Temporal values are freed from memory. (a$ > b$)
    '''
    (tmp1, tmp2, output) = _str_oper(ins.quad[2], ins.quad[3])
    output.append('call __STRGT')
    output.append('push af')
    REQUIRES.add('string.asm')
    return output


def _lestr(ins):
    ''' Compares & pops top 2 strings out of the stack.
    Temporal values are freed from memory. (a$ <= b$)
    '''
    (tmp1, tmp2, output) = _str_oper(ins.quad[2], ins.quad[3])
    output.append('call __STRLE')
    output.append('push af')
    REQUIRES.add('string.asm')
    return output


def _gestr(ins):
    ''' Compares & pops top 2 strings out of the stack.
    Temporal values are freed from memory. (a$ >= b$)
    '''
    (tmp1, tmp2, output) = _str_oper(ins.quad[2], ins.quad[3])
    output.append('call __STRGE')
    output.append('push af')
    REQUIRES.add('string.asm')
    return output


def _eqstr(ins):
    ''' Compares & pops top 2 strings out of the stack.
    Temporal values are freed from memory. (a$ == b$)
    '''
    (tmp1, tmp2, output) = _str_oper(ins.quad[2], ins.quad[3])
    output.append('call __STREQ')
    output.append('push af')
    REQUIRES.add('string.asm')
    return output


def _nestr(ins):
    ''' Compares & pops top 2 strings out of the stack.
    Temporal values are freed from memory. (a$ != b$)
    '''
    (tmp1, tmp2, output) = _str_oper(ins.quad[2], ins.quad[3])
    output.append('call __STRNE')
    output.append('push af')
    REQUIRES.add('string.asm')
    return output


def _lenstr(ins):
    ''' Returns string length
    '''
    (tmp1, output) = _str_oper(ins.quad[2], no_exaf=True)
    if tmp1:
        output.append('push hl')

    output.append('call __STRLEN')
    output.extend(_free_sequence(tmp1))
    output.append('push hl')
    REQUIRES.add('strlen.asm')
    return output
