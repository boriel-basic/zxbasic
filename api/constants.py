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
    const = 'const'  # 5  # constant literal value e.g. 5 or "AB"

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

    TYPE_SIZES = {
        byte_: 1, ubyte: 1,
        integer: 2, uinteger: 2,
        long_: 4, ulong: 4,
        fixed: 4, float_: 5,
        string: 2, unknown: 0
    }

    @classmethod
    @property
    def types(clss):
        return clss.__dict__.values()

    @classmethod
    def size(clss, type_):
        return TYPE_SIZES.get(type_, TYPE_SIZES[clss.unknown])

    @classmethod
    @property
    def integral(clss):
        return (clss.byte_, clss.ubyte, clss.integer, clss.uinteger,
                clss.long_, clss.ulong)

    @classmethod
    @property
    def signed(clss):
        return (clss.byte_, clss.integer, clss.long_, clss.fixed, clss.float_)

    @classmethod
    @property
    def unsigned(clss):
        return (clss.ubyte, clss.uinteger, clss.ulong)

    @classmethod
    @property
    def decimals(clss):
        return (clss.fixed, clss.float_)

    @classmethod
    @property
    def numbers(clss):
        return tuple(list(clss.integral) + list(clss.decimals))

    @classmethod
    def is_valid(clss, type_):
        ''' Whether the given type is
        valid or not.
        '''
        return type_ in clss.types

    @classmethod
    def is_signed(clss, type_):
        return type_ in clss.signed

    @classmethod
    def is_unsigned(clss, type_):
        return type_ in clss.unsigned

    @classmethod
    def to_signed(clss, type_):
        ''' Return signed type or equivalent
        '''
        if type_ in clss.unsigned:
            return {TYPE.ubyte: TYPE.byte_,
                    TYPE.uinteger: TYPE.integer,
                    TYPE.ulong: TYPE.long_}[type_]
        if type_ in clss.decimals or type_ in clss.signed:
            return type_
        return clss.unknown


class SCOPE(object):
    ''' Enum scopes
    '''
    unknown = None
    global_ = 'global'
    local = 'local'


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
