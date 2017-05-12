#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .decorator import classproperty

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
    label = 'label'  # 4 Labels
    const = 'const'  # 5  # constant literal value e.g. 5 or "AB"
    sub = 'sub'  # 6  # subroutine
    type_ = 'type'  # 7  # type

    _CLASS_NAMES = {
        unknown: '(unknown)',
        var: 'var',
        array: 'array',
        function: 'function',
        label: 'label',
        const: 'const',
        sub: 'sub',
        type_: 'type'
    }

    @classproperty
    def classes(cls):
        return (cls.unknown, cls.var, cls.array, cls.function, cls.sub,
                cls.const, cls.label)

    @classmethod
    def is_valid(cls, class_):
        ''' Whether the given class is
        valid or not.
        '''
        return class_ in cls.classes

    @classmethod
    def to_string(cls, class_):
        assert cls.is_valid(class_)
        return cls._CLASS_NAMES[class_]


class ARRAY(object):
    ''' Enums array constants
    '''
    bound_size = 2  # This might change depending on arch, program, etc..
    bound_count = 2  # Size of bounds counter
    array_type_size = 1  # Size of array type


class TYPE(object):
    ''' Enums type constants
    '''
    auto = unknown = None
    byte_ = 1
    ubyte = 2
    integer = 3
    uinteger = 4
    long_ = 5
    ulong = 6
    fixed = 7
    float_ = 8
    string = 9

    TYPE_SIZES = {
        byte_: 1, ubyte: 1,
        integer: 2, uinteger: 2,
        long_: 4, ulong: 4,
        fixed: 4, float_: 5,
        string: 2, unknown: 0
    }

    TYPE_NAMES = {
        byte_: 'byte', ubyte: 'ubyte',
        integer: 'integer', uinteger: 'uinteger',
        long_: 'long', ulong: 'ulong',
        fixed: 'fixed', float_: 'float',
        string: 'string', unknown: 'none'
    }

    @classproperty
    def types(clss):
        return tuple(clss.TYPE_SIZES.keys())

    @classmethod
    def size(clss, type_):
        return clss.TYPE_SIZES.get(type_, None)

    @classproperty
    def integral(clss):
        return (clss.byte_, clss.ubyte, clss.integer, clss.uinteger,
                clss.long_, clss.ulong)

    @classproperty
    def signed(clss):
        return (clss.byte_, clss.integer, clss.long_, clss.fixed, clss.float_)

    @classproperty
    def unsigned(clss):
        return (clss.ubyte, clss.uinteger, clss.ulong)

    @classproperty
    def decimals(clss):
        return (clss.fixed, clss.float_)

    @classproperty
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

    @classmethod
    def to_string(clss, type_):
        ''' Return ID representtion (string) of a type
        '''
        return clss.TYPE_NAMES[type_]

    @classmethod
    def to_type(clss, typename):
        ''' Converts a type ID to name. On error returns None
        '''
        NAME_TYPES = {clss.TYPE_NAMES[x]: x for x in clss.TYPE_NAMES}
        return NAME_TYPES.get(typename, None)


class SCOPE(object):
    ''' Enum scopes
    '''
    unknown = None
    global_ = 'global'
    local = 'local'
    parameter = 'parameter'

    _names = {
        unknown: 'unknown',
        global_: 'global',
        local: 'local',
        parameter: 'parameter'
    }

    @classmethod
    def is_valid(cls, scope):
        return cls._names.get(scope, None) is not None

    @classmethod
    def to_string(cls, scope):
        assert cls.is_valid(scope)
        return cls._names[scope]



class KIND(object):
    ''' Enum kind
    '''
    unknown = None
    var = 'var'
    function = 'function'
    sub = 'sub'
    type_ = 'type'

    _NAMES = {
        unknown: '(unknown)',
        var: 'variable',
        function: 'function',
        sub: 'subroutine',
        type_: 'type'
    }

    @classmethod
    def is_valid(cls, kind):
        return cls._NAMES.get(kind, None) is not None

    @classmethod
    def to_string(cls, kind):
        assert cls.is_valid(kind)
        return cls._NAMES.get(kind)


class CONVENTION(object):
    unknown = None
    fastcall = '__fastcall__'
    stdcall = '__stdcall__'

    _NAMES = {
        unknown: '(unknown)',
        fastcall: '__fastcall__',
        stdcall: '__stdcall__'
    }

    @classmethod
    def is_valid(cls, convention):
        return cls._NAMES.get(convention, None) is not None

    @classmethod
    def to_string(cls, convention):
        assert cls.is_valid(convention)
        return cls._NAMES[convention]



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

"""
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
"""
# Maps deprecated suffixes to types
SUFFIX_TYPE = {'$': TYPE.string, '%': TYPE.integer, '&': TYPE.long_}


'''
# ----------------------------------------------------------------------
# Internal constants. Don't touch unless you know what are you doing
# ----------------------------------------------------------------------
MIN_STRSLICE_IDX = 0      # Min. string slicing position
MAX_STRSLICE_IDX = 65534  # Max. string slicing position

# Platform dependant. This is the default (Z80).
PTR_TYPE = TYPE.uinteger
'''
