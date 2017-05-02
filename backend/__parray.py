#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains local array (both parameters and
# comparation intermediate-code traductions
# --------------------------------------------------------------

from .__common import REQUIRES
from .__float import _fpush
from .__f16 import f16


def _paddr(offset):
    ''' Generic array address parameter loading.
    Emmits output code for setting IX at the right location.
    bytes = Number of bytes to load:
        1 => 8 bit value
        2 => 16 bit value / string
        4 => 32 bit value / f16 value
        5 => 40 bit value
    '''
    output = []

    indirect = offset[0] == '*'
    if indirect:
        offset = offset[1:]

    I = int(offset)
    if I >= 0:
        I += 4 # Return Address + "push IX"

    output.append('push ix')
    output.append('pop hl')
    output.append('ld de, %i' % I)
    output.append('add hl, de')

    if indirect:
        output.append('ld c, (hl)')
        output.append('inc hl')
        output.append('ld h, (hl)')
        output.append('ld l, c')

    output.append('call __ARRAY')
    REQUIRES.add('array.asm')
    return output


def _paaddr(ins):
    ''' Loads address of an array element into the stack
    '''
    output = _paddr(ins.quad[2])
    output.append('push hl')

    return output



def _paload8(ins):
    ''' Loads an 8 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _paddr(ins.quad[2])
    output.append('ld a, (hl)')
    output.append('push af')

    return output



def _paload16(ins):
    ''' Loads a 16 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _paddr(ins.quad[2])
    
    output.append('ld e, (hl)')
    output.append('inc hl')
    output.append('ld d, (hl)')
    output.append('ex de, hl')
    output.append('push hl')

    return output



def _paload32(ins):
    ''' Load a 32 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _paddr(ins.quad[2])

    output.append('call __ILOAD32')
    output.append('push de')
    output.append('push hl')

    REQUIRES.add('iload32.asm')

    return output



def _paloadf(ins):
    ''' Loads a floating point value from a memory address.
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _paddr(ins.quad[2])
    output.append('call __ILOADF')
    output.extend(_fpush())

    REQUIRES.add('iloadf.asm')

    return output



def _paloadstr(ins):
    ''' Loads a string value from a memory address.
    '''
    output = _paddr(ins.quad[2])

    output.append('call __ILOADSTR')
    output.append('push hl')
    REQUIRES.add('loadstr.asm')

    return output
        


def _pastore8(ins):
    ''' Stores 2º operand content into address of 1st operand.
    1st operand is an array element. Dimensions are pushed into the 
    stack.
    Use '*' for indirect store on 1st operand (A pointer to an array)
    '''
    output = _paddr(ins.quad[1])

    value = ins.quad[2]
    if value[0] == '*':
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        value = int(ins.quad[2]) & 0xFFFF
        if indirect:
            output.append('ld a, (%i)' % value)
            output.append('ld (hl), a')
        else:
            value &= 0xFF
            output.append('ld (hl), %i' % value)
    except ValueError:
        output.append('pop af')
        output.append('ld (hl), a')

    return output



def _pastore16(ins):
    ''' Stores 2º operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    Use '*' for indirect store on 1st operand.
    '''
    output = _paddr(ins.quad[1])

    value = ins.quad[2]
    if value[0] == '*':
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        value = int(ins.quad[2]) & 0xFFFF
        output.append('ld de, %i' % value)
        if indirect:
            output.append('call __LOAD_DE_DE')
            REQUIRES.add('lddede.asm')

    except ValueError:
        output.append('pop de')

    output.append('ld (hl), e')
    output.append('inc hl')
    output.append('ld (hl), d')

    return output



def _pastore32(ins):
    ''' Stores 2º operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    '''
    output = _paddr(ins.quad[1])

    value = ins.quad[2]
    if value[0] == '*':
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        value = int(ins.quad[2]) & 0xFFFFFFFF # Immediate?
        if indirect:
            output.append('push hl')
            output.append('ld hl, %i' % (value & 0xFFFF))
            output.append('call __ILOAD32')
            output.append('ld b, h')
            output.append('ld c, l') # BC = Lower 16 bits
            output.append('pop hl')
            REQUIRES.add('iload32.asm')
        else:
            output.append('ld de, %i' % (value >> 16))
            output.append('ld bc, %i' % (value & 0xFFFF))
    except ValueError:
        output.append('pop bc')
        output.append('pop de')

    output.append('call __STORE32')
    REQUIRES.add('store32.asm')

    return output



def _pastoref16(ins):
    ''' Stores 2º operand content into address of 1st operand.
    storef16 a, x =>  *(&a) = x
    '''
    output = _paddr(ins.quad[1])

    value = ins.quad[2]
    if value[0] == '*':
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        if indirect:
            value = int(ins.quad[2])
            output.append('push hl')
            output.append('ld hl, %i' % (value & 0xFFFF))
            output.append('call __ILOAD32')
            output.append('ld b, h')
            output.append('ld c, l') # BC = Lower 16 bits
            output.append('pop hl')
            REQUIRES.add('iload32.asm')
        else:
            de, hl = f16(value)
            output.append('ld de, %i' % de)
            output.append('ld bc, %i' % hl)
    except ValueError:
        output.append('pop bc')
        output.append('pop de')

    output.append('call __STORE32')
    REQUIRES.add('store32.asm')

    return output



def _pastoref(ins):
    ''' Stores a floating point value into a memory address.
    '''
    output = _paddr(ins.quad[1])

    value = ins.quad[2]
    if value[0] == '*':
        value = value[1:]
        indirect = True
    else:
        indirect = False

    try:
        if indirect:
            value = int(value) & 0xFFFF # Inmediate?
            output.append('push hl')
            output.append('ld hl, %i' % value)
            output.append('call __ILOADF')
            output.append('ld a, c')
            output.append('ld b, h')
            output.append('ld c, l') # BC = Lower 16 bits, A = Exp
            output.append('pop hl')     # Recovers pointer
            REQUIRES.add('iloadf.asm')
        else:
            value = float(value) # Inmediate?
            C, DE, HL = fp.immediate_float(value)
            output.append('ld a, %s' % C)
            output.append('ld de, %s' % DE)
            output.append('ld bc, %s' % HL)
    except ValueError:
        output.append('pop bc')
        output.append('pop de')
        output.append('ex (sp), hl') # Preserve HL for STOREF
        output.append('ld a, l')
        output.append('pop hl')

    output.append('call __STOREF')
    REQUIRES.add('storef.asm')

    return output



def _pastorestr(ins):
    ''' Stores a string value into a memory address.
    It copies content of 2nd operand (string), into 1st, reallocating
    dynamic memory for the 1st str. These instruction DOES ALLOW
    inmediate strings for the 2nd parameter, starting with '#'.
    '''
    output = _paddr(ins.quad[1])
    temporal = False
    value = ins.quad[2]

    indirect = value[0] == '*'
    if indirect:
        value = value[1:]

    immediate = value[0]
    if immediate:
        value = value[1:]

    if value[0] == '_':
        if indirect:
            if immediate:
                output.append('ld de, (%s)' % value)
            else:
                output.append('ld de, (%s)' % value)
                output.append('call __LOAD_DE_DE')
                REQUIRES.add('lddede.asm')
        else:
            if immediate:
                output.append('ld de, %s' % value)
            else:
                output.append('ld de, (%s)' % value)
    else:
        output.append('pop de')
        temporal = True

        if indirect:
            output.append('call __LOAD_DE_DE')
            REQUIRES.add('lddede.asm')

    if not temporal:
        output.append('call __STORE_STR')
        REQUIRES.add('storestr.asm')
    else: # A value already on dynamic memory
        output.append('call __STORE_STR2')
        REQUIRES.add('storestr2.asm')

    return output



