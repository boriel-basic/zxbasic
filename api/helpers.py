#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------


from api import global_
from constants import TYPE_SIZES


# ----------------------------------------------------------------------
# Function for checking some arguments
# ----------------------------------------------------------------------
def is_SYMBOL(token, *symbols):
    ''' Returns True if ALL of the given argument are AST nodes
    of the given token (e.g. 'BINARY')
    '''
    for sym in symbols:
        if sym.token != token:
            return False

    return True


def is_string(*p):
    return is_SYMBOL('STRING', *p)


def is_const(*p):
    return is_SYMBOL('CONST', *p)


def is_number(*p):
    ''' Returns True if ALL of the arguments are AST nodes
    containing NUMBER constants
    '''
    try:
        for i in p:
            if i.token != 'NUMBER' and (i.token != 'ID' or i.class_ != 'const'):
                return False

        return True
    except:
        pass

    return False


def is_id(*p):
    ''' Returns True if ALL of the arguments are AST nodes
    containing ID
    '''
    return is_SYMBOL('ID', *p)


def is_integer(*p):
    try:
        for i in p:
            if i.type_ not in ('i8', 'u8', 'i16', 'u16', 'i32', 'u32'):
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
            if i.type_ not in ('u8', 'u16', 'u32'):
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
            if i.type_ not in ('float', 'fixed', 'i8', 'i16', 'i32'):
                return False

        return True
    except:
        pass

    return False


def is_numeric(*p):
    try:
        for i in p:
            if i.type_ == 'string':
                return False

        return True
    except:
        pass

    return False


def is_type(type_, *p):
    ''' True if all args have the same type
    '''
    try:
        for i in p:
            if i.type_ != type_:
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
            if i.scope == 'global' and i.type_ not in ('string'):
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

    if a.type_ == b.type_:    # Both types are the same?
        return a.type_        # Returns it

    if a.type_ is None and b.type_ is None:
        return global_.DEFAULT_TYPE

    if a.type_ is None:
        return b.type_

    if b.type_ is None:
        return a.type_

    types = (a.type_, b.type_)

    if 'float' in types:
        return 'float'

    if 'fixed' in types:
        return 'fixed'

    if 'string' in types:
        return 'string'

    result = a.type_ if TYPE_SIZES[a.type_] > TYPE_SIZES[b.type_] else b.type_

    if not is_unsigned(a, b):
        result = 'i' + result[1:]

    return result


