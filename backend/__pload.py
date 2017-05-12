#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: et:ts=4:sw=4

# --------------------------------------------------------------
# Copyleft (k) 2008, by Jose M. Rodriguez-Rosa
# (a.k.a. Boriel, http://www.boriel.com)
#
# This module contains parameter load
# intermediate-code traductions
# --------------------------------------------------------------


from .__common import REQUIRES, is_int
from .__8bit import int8, _8bit_oper
from .__16bit import int16, _16bit_oper
from .__32bit import _32bit_oper
from .__f16 import _f16_oper
from .__float import _fpush, _float_oper


def _paddr(ins):
    ''' Returns code secuence which points to
    local variable or parameter (HL)
    '''
    output = []

    oper = ins.quad[1]
    indirect = (oper[0] == '*')
    if indirect:
        oper = oper[1:]

    I = int(oper)
    if I >= 0:
        I += 4 # Return Address + "push IX"

    output.append('push ix')
    output.append('pop hl')
    output.append('ld de, %i' % I)
    output.append('add hl, de')

    if indirect:
        output.append('ld e, (hl)')
        output.append('inc hl')
        output.append('ld h, (hl)')
        output.append('ld l, e')

    output.append('push hl')
    return output
    


def _pload(offset, size):
    ''' Generic parameter loading.
    Emmits output code for setting IX at the right location.
    size = Number of bytes to load:
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
    if I >= 0: # If it is a parameter, round up to even bytes
        I += 4 + (size % 2 if not indirect else 0) # Return Address + "push IX"

    ix_changed = (indirect or size < 5) and (abs(I) + size) > 127 # Offset > 127 bytes. Need to change IX
    if ix_changed: # more than 1 byte
        output.append('push ix')
        output.append('ld de, %i' % I)
        output.append('add ix, de')
        I = 0
    elif size == 5: # For floating point numbers we always use DE as IX offset
        output.append('push ix')
        output.append('pop hl')
        output.append('ld de, %i' % I)
        output.append('add hl, de')
        I = 0

    if indirect:
        output.append('ld h, (ix%+i)' % (I + 1))
        output.append('ld l, (ix%+i)' % I)
        
        if size == 1:
            output.append('ld a, (hl)')
        elif size == 2:
            output.append('ld c, (hl)')
            output.append('inc hl')
            output.append('ld h, (hl)')
            output.append('ld l, c')
        elif size == 4:
            output.append('call __ILOAD32')
            REQUIRES.add('iload32.asm')
        else: # Floating point
            output.append('call __ILOADF')
            REQUIRES.add('iloadf.asm')
    else:
        if size == 1:
            output.append('ld a, (ix%+i)' % I)
        else:
            if size <= 4: # 16/32bit integer, low part
                output.append('ld l, (ix%+i)' % I)
                output.append('ld h, (ix%+i)' % (I + 1))

                if size > 2: # 32 bit integer, high part
                    output.append('ld e, (ix%+i)' % (I + 2))
                    output.append('ld d, (ix%+i)' % (I + 3))

            else: # Floating point
                output.append('call __PLOADF')
                REQUIRES.add('ploadf.asm')
            
    if ix_changed:
        output.append('pop ix')

    return output
    


def _pload8(ins):
    ''' Loads from stack pointer (SP) + X, being
    X 2st parameter.

    2st operand must be a SIGNED integer.
    1nd operand cannot be an immediate nor an address, but
    can be an indirect (*) parameter, for function 'ByRef' implementation.
    '''
    output = _pload(ins.quad[2], 1)
    output.append('push af')
    return output



def _pload16(ins):
    ''' Loads from stack pointer (SP) + X, being
    X 2st parameter.

    1st operand must be a SIGNED integer.
    2nd operand cannot be an immediate nor an address.
    '''
    output = _pload(ins.quad[2], 2)
    output.append('push hl')
    return output



def _pload32(ins):
    ''' Loads from stack pointer (SP) + X, being
    X 2st parameter.

    1st operand must be a SIGNED integer.
    2nd operand cannot be an immediate nor an address.
    '''
    output = _pload(ins.quad[2], 4)
    output.append('push de')
    output.append('push hl')
    return output
    


def _ploadf(ins):
    ''' Loads from stack pointer (SP) + X, being
    X 2st parameter.

    1st operand must be a SIGNED integer.
    '''
    output = _pload(ins.quad[2], 5)
    output.extend(_fpush())
    return output


def _ploadstr(ins):
    ''' Loads from stack pointer (SP) + X, being
    X 2st parameter.

    1st operand must be a SIGNED integer.
    2nd operand cannot be an immediate nor an address.
    '''
    output = _pload(ins.quad[2], 2)
    if ins.quad[1][0] != '$':
        output.append('call __LOADSTR')
        REQUIRES.add('loadstr.asm')

    output.append('push hl')
    return output


def _fploadstr(ins):
    ''' Loads from stack pointer (SP) + X, being
    X 2st parameter.

    1st operand must be a SIGNED integer.
    Unlike ploadstr, this version does not push the result
    back into the stack.
    '''
    output = _pload(ins.quad[2], 2)
    if ins.quad[1][0] != '$':
        output.append('call __LOADSTR')
        REQUIRES.add('loadstr.asm')

    return output


def _pstore8(ins):
    ''' Stores 2nd parameter at stack pointer (SP) + X, being
    X 1st parameter.

    1st operand must be a SIGNED integer.
    '''
    value = ins.quad[2]
    offset = ins.quad[1]
    indirect = offset[0] == '*'
    size = 0 
    if indirect:
        offset = offset[1:]
        size = 1

    I = int(offset)
    if I >= 0:
        I += 4 # Return Address + "push IX" 
        if not indirect:
            I += 1 # F flag ignored

    if is_int(value):
        output = []
    else:
        output = _8bit_oper(value)

    ix_changed = not (-128 + size <= I <= 127 - size) # Offset > 127 bytes. Need to change IX
    if ix_changed: # more than 1 byte
        output.append('push ix')
        output.append('pop hl')
        output.append('ld de, %i' % I)
        output.append('add hl, de')
        
    if indirect:
        if ix_changed:
            output.append('ld c, (hl)') 
            output.append('inc hl')
            output.append('ld h, (hl)')
            output.append('ld l, c')
        else:
            output.append('ld h, (ix%+i)' % (I + 1))
            output.append('ld l, (ix%+i)' % I)
        
        if is_int(value):
            output.append('ld (hl), %i' % int8(value))
        else:
            output.append('ld (hl), a')

        return output

    # direct store
    if ix_changed:
        if is_int(value):
            output.append('ld (hl), %i' % int8(value))
        else:
            output.append('ld (hl), a')

        return output

    if is_int(value):
        output.append('ld (ix%+i), %i' % (I, int8(value)))
    else:
        output.append('ld (ix%+i), a' % I)

    return output



def _pstore16(ins):
    ''' Stores 2nd parameter at stack pointer (SP) + X, being
    X 1st parameter.

    1st operand must be a SIGNED integer.
    '''
    value = ins.quad[2]
    offset = ins.quad[1]
    indirect = offset[0] == '*'
    size = 1 
    if indirect:
        offset = offset[1:]

    I = int(offset)
    if I >= 0:
        I += 4 # Return Address + "push IX" 

    if is_int(value):
        output = []
    else:
        output = _16bit_oper(value)

    ix_changed = not (-128 + size <= I <= 127 - size) # Offset > 127 bytes. Need to change IX
        
    if indirect:
        if is_int(value):
            output.append('ld hl, %i' % int16(value))

        output.append('ld bc, %i' % I)
        output.append('call __PISTORE16')
        REQUIRES.add('istore16.asm')
        return output

    # direct store
    if ix_changed: # more than 1 byte
        if not is_int(value):
            output.append('ex de, hl')

        output.append('push ix')
        output.append('pop hl')
        output.append('ld bc, %i' % I)
        output.append('add hl, bc')

        if is_int(value):
            v = int16(value)
            output.append('ld (hl), %i' % (v & 0xFF))
            output.append('inc hl')
            output.append('ld (hl), %i' % (v >> 8))
            return output
        else:
            output.append('ld (hl), e')
            output.append('inc hl')
            output.append('ld (hl), d')
            return output

    if is_int(value):
        v = int16(value)
        output.append('ld (ix%+i), %i' % (I, v & 0xFF))
        output.append('ld (ix%+i), %i' % (I + 1, v >> 8))
    else:
        output.append('ld (ix%+i), l' % I)
        output.append('ld (ix%+i), h' % (I + 1))

    return output



def _pstore32(ins):
    ''' Stores 2nd parameter at stack pointer (SP) + X, being
    X 1st parameter.

    1st operand must be a SIGNED integer.
    '''
    value = ins.quad[2]
    offset = ins.quad[1]
    indirect = offset[0] == '*'
    bytes = 3 
    if indirect:
        offset = offset[1:]

    I = int(offset)
    if I >= 0:
        I += 4 # Return Address + "push IX" 

    output = _32bit_oper(value)
    ix_changed = not (-128 + bytes <= I <= 127 - bytes) # Offset > 127 bytes. Need to change IX
        
    if indirect:
        output.append('ld bc, %i' % I)
        output.append('call __PISTORE32')
        REQUIRES.add('pistore32.asm')
        return output

    # direct store
    output.append('ld bc, %i' % I)
    output.append('call __PSTORE32')
    REQUIRES.add('pstore32.asm')

    return output
    


def _pstoref16(ins):
    ''' Stores 2nd parameter at stack pointer (SP) + X, being
    X 1st parameter.

    1st operand must be a SIGNED integer.
    '''
    value = ins.quad[2]
    offset = ins.quad[1]
    indirect = offset[0] == '*'
    bytes = 3 
    if indirect:
        offset = offset[1:]

    I = int(offset)
    if I >= 0:
        I += 4 # Return Address + "push IX" 

    output = _f16_oper(value)
    ix_changed = not (-128 + bytes <= I <= 127 - bytes) # Offset > 127 bytes. Need to change IX
        
    if indirect:
        output.append('ld bc, %i' % I)
        output.append('call __PISTORE32')
        REQUIRES.add('pistore32.asm')
        return output

    # direct store
    output.append('ld bc, %i' % I)
    output.append('call __PSTORE32')
    REQUIRES.add('pstore32.asm')

    return output



def _pstoref(ins):
    ''' Stores 2nd parameter at stack pointer (SP) + X, being
    X 1st parameter.

    1st operand must be a SIGNED integer.
    '''
    value = ins.quad[2]
    offset = ins.quad[1]
    indirect = offset[0] == '*'
    if indirect:
        offset = offset[1:]

    I = int(offset)
    if I >= 0:
        I += 4 # Return Address + "push IX" 

    output = _float_oper(value)
        
    if indirect:
        output.append('ld hl, %i' % I)
        output.append('call __PISTOREF')
        REQUIRES.add('storef.asm')
        return output

    # direct store
    output.append('ld hl, %i' % I)
    output.append('call __PSTOREF')
    REQUIRES.add('pstoref.asm')

    return output



def _pstorestr(ins):
    ''' Stores 2nd parameter at stack pointer (SP) + X, being
    X 1st parameter.

    1st operand must be a SIGNED integer.

    Note: This procedure proceeds as _pstore16, since STRINGS are 16bit pointers.
    '''
    output = []
    temporal = False

    # 2nd operand first, because must go into the stack
    value = ins.quad[2]

    if value[0] == '*':
        value = value[1:]
        indirect = True
    else:
        indirect = False

    if value[0] == '_':
        output.append('ld de, (%s)' % value)

        if indirect:
            output.append('call __LOAD_DE_DE')
            REQUIRES.add('lddede.asm')

    elif value[0] == '#':
        output.append('ld de, %s' % value[1:])
    else:
        output.append('pop de')
        temporal = value[0] != '$'
        if indirect:
            output.append('call __LOAD_DE_DE')
            REQUIRES.add('lddede.asm')

    # Now 1st operand
    value = ins.quad[1]
    if value[0] == '*':
        value = value[1:]
        indirect = True
    else:
        indirect = False

    I = int(value)
    if I >= 0:
        I += 4 # Return Address + "push IX" 

    output.append('ld bc, %i' % I)

    if not temporal:
        if indirect:
            output.append('call __PISTORE_STR')
            REQUIRES.add('storestr.asm')
        else:
            output.append('call __PSTORE_STR')
            REQUIRES.add('pstorestr.asm')
    else:
        if indirect:
            output.append('call __PISTORE_STR2')
            REQUIRES.add('storestr2.asm')
        else:
            output.append('call __PSTORE_STR2')
            REQUIRES.add('pstorestr2.asm')

    return output

