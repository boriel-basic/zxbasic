#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

__all__ = [
    'ID_CLASSES', 'DEPRECATED_SUFFIXES', 'ID_TYPES',
    'TYPE_NAMES', 'NAME_TYPES', 'TYPE_SIZES', 'SUFFIX_TYPE',
    'PTR_TYPE'
]

# -------------------------------------------------
# Global constants
# -------------------------------------------------

# ----------------------------------------------------------------------
# Class enums
# ----------------------------------------------------------------------


class CLASS(object):
    ''' Enums class constants
    '''
    unknown = 'unknown'  # 0
    var = 'var'  # 1  # scalar variable
    array = 'array'  # 2  # array variable
    function = 'function'  # 3  # function
    sub = 'sub'  # 4  # subroutine

    @classmethod
    @property
    def classes(clss):
        return clss.__dict__.values()

    @classmethod
    def is_valid(clss, class_):
        ''' Whether the given class is
        valid or not.
        '''
        return class_ in clss.classes


class ARRAY(object):
    ''' Enums array constants
    '''
    bound_size = 2  # This might change depending on arch, program, etc..
    bound_count = 2  # Size of bounds conter
    array_type_size = 1  # Size of array type


class TYPE(object):
    ''' Enums type constants
    '''
    unknown = None
    byte_ = 'i8'
    ubyte = 'u8'
    integer = 'i16'
    uinteger = 'u16'
    long_ = 'i32'
    ulong = 'u32'
    fixed = 'fixed'
    float_ = 'float'
    string = 'string'

    @classmethod
    @property
    def types(clss):
        return clss.__dict__.values()

    @classmethod
    def is_valid(clss, class_):
        ''' Whether the given class is
        valid or not.
        '''
        return class_ in clss.types


# ----------------------------------------------------------------------
# Identifier Class (variable, function, label, array)
# ----------------------------------------------------------------------
ID_CLASSES = CLASS.classes

# ----------------------------------------------------------------------
# Deprecated suffixes for variable names, such as "a$"
# ----------------------------------------------------------------------
DEPRECATED_SUFFIXES = ('$', '%', '&')

# ----------------------------------------------------------------------
# Identifier type
# i8 = Integer, 8 bits
# u8 = Unsigned, 8 bits and so on
# ----------------------------------------------------------------------
ID_TYPES = TYPE.types

TYPE_NAMES = {
    'byte': TYPE.byte_, 'ubyte': TYPE.ubyte,
    'integer': TYPE.integer, 'uinteger': TYPE.uinteger,
    'long': TYPE.long_, 'ulong': TYPE.ulong,
    'fixed': TYPE.fixed, 'float': TYPE.float_,
    'string': TYPE.string, 'none': TYPE.unknown
}


# The reverse of above
NAME_TYPES = dict([(TYPE_NAMES[x], x) for x in TYPE_NAMES.keys()])

TYPE_SIZES = {
    TYPE.byte_: 1, TYPE.ubyte: 1,
    TYPE.integer: 2, TYPE.uinteger: 2,
    TYPE.long_: 4, TYPE.ulong: 4,
    TYPE.fixed: 4, TYPE.float_: 5,
    TYPE.string: 2, TYPE.unknown: 0
}

# Maps suffix to types
SUFFIX_TYPE = {'$': TYPE.string, '%': TYPE.integer, '&': TYPE.long_}


# ----------------------------------------------------------------------
# Internal constants. Don't touch unless you know what are you doing
# ----------------------------------------------------------------------
MIN_STRSLICE_IDX = 0      # Min. string slicing position
MAX_STRSLICE_IDX = 65534  # Max. string slicing position

# Platform dependant. This is the default (Z80).
PTR_TYPE = TYPE.uinteger
