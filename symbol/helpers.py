#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------


from obj import gl
from constants import TYPE_SIZES


# ----------------------------------------------------------------------
# Function for checking some arguments
# ----------------------------------------------------------------------
def is_number(*p):
    ''' Returns True if ALL of the arguments are AST nodes
    containing NUMBER constants
    '''
    try:
        for i in p:
            if i.token != 'NUMBER' and (i.token != 'ID' or i._class != 'const'):
                return False

        return True
    except:
        pass

    return False


def is_id(*p):
    ''' Returns True if ALL of the arguments are AST nodes
    containing ID
    '''
    try:
        for i in p:
            if i.token != 'ID':
                return False

        return True
    except:
        pass

    return False


def is_integer(*p):
    try:
        for i in p:
            if i._type not in ('i8', 'u8', 'i16', 'u16', 'i32', 'u32'):
                return False

        return True

    except:
        pass

    return False



def is_unsigned(*p):
    ''' Returns false unles all types in p are unsigned
    '''
    try:
        for i in p:
            if i._type not in ('u8', 'u16', 'u32'):
                return False

        return True

    except:
        pass

    return False



def is_signed(*p):
    ''' Returns false unles all types in p are signed
    '''
    try:
        for i in p:
            if i._type not in ('float', 'fixed', 'i8', 'i16', 'i32'):
                return False

        return True

    except:
        pass

    return False


def is_numeric(*p):
    try:
        for i in p:
            if i._type == 'string':
                return False

        return True

    except:
        pass

    return False


def is_string(*p):
    try:
        for i in p:
            if i.token != 'STRING':
                return False

        return True

    except:
        pass

    return False


def is_const(*p):
    ''' True if all the given nodes are
    constant expressions.'''
    try:
        for i in p:
            if i.token != 'CONST':
                return False

        return True

    except:
        pass

    return False


def is_type(_type, *p):
    ''' True if all args have the same type
    '''
    try:
        for i in p:
            if i._type != _type:
                return False

        return True

    except:
        pass

    return False


def is_dynamic(*p):
    ''' True if all args are dynamic (e.g. Strings, dynamic arrays, etc)
    '''
    try:
        for i in p:
            if i.scope == 'global' and i._type not in ('string'):
                return False

        return True

    except:
        pass

    return False



def common_type(a, b):
    ''' Returns a type which is common for both a and b types.
    Returns None if no common types allowed.
    '''
    if a is None or b is None:
        return None

    if a._type == b._type:    # Both types are the same?
        return a._type        # Returns it

    if a._type is None and b._type is None:
        return gl.DEFAULT_TYPE

    if a._type is None:
        return b._type

    if b._type is None:
        return a._type

    types = (a._type, b._type)

    if 'float' in types:
        return 'float'

    if 'fixed' in types:
        return 'fixed'

    if 'string' in types:
        return 'string'

    result = a._type if TYPE_SIZES[a._type] > TYPE_SIZES[b._type] else b._type

    if not is_unsigned(a, b):
        result = 'i' + result[1:]

    return result


