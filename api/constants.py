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
    """ Enums class constants
    """
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
        """ Whether the given class is
        valid or not.
        """
        return class_ in cls.classes

    @classmethod
    def to_string(cls, class_):
        assert cls.is_valid(class_)
        return cls._CLASS_NAMES[class_]


class ARRAY(object):
    """ Enums array constants
    """
    bound_size = 2  # This might change depending on arch, program, etc..
    bound_count = 2  # Size of bounds counter
    array_type_size = 1  # Size of array type


class TYPE(object):
    """ Enums type constants
    """
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
    def types(cls):
        return tuple(cls.TYPE_SIZES.keys())

    @classmethod
    def size(cls, type_):
        return cls.TYPE_SIZES.get(type_, None)

    @classproperty
    def integral(cls):
        return (cls.byte_, cls.ubyte, cls.integer, cls.uinteger,
                cls.long_, cls.ulong)

    @classproperty
    def signed(cls):
        return (cls.byte_, cls.integer, cls.long_, cls.fixed, cls.float_)

    @classproperty
    def unsigned(cls):
        return (cls.ubyte, cls.uinteger, cls.ulong)

    @classproperty
    def decimals(cls):
        return (cls.fixed, cls.float_)

    @classproperty
    def numbers(cls):
        return tuple(list(cls.integral) + list(cls.decimals))

    @classmethod
    def is_valid(cls, type_):
        """ Whether the given type is
        valid or not.
        """
        return type_ in cls.types

    @classmethod
    def is_signed(cls, type_):
        return type_ in cls.signed

    @classmethod
    def is_unsigned(cls, type_):
        return type_ in cls.unsigned

    @classmethod
    def to_signed(cls, type_):
        """ Return signed type or equivalent
        """
        if type_ in cls.unsigned:
            return {TYPE.ubyte: TYPE.byte_,
                    TYPE.uinteger: TYPE.integer,
                    TYPE.ulong: TYPE.long_}[type_]
        if type_ in cls.decimals or type_ in cls.signed:
            return type_
        return cls.unknown

    @classmethod
    def to_string(cls, type_):
        """ Return ID representtion (string) of a type
        """
        return cls.TYPE_NAMES[type_]

    @classmethod
    def to_type(cls, typename):
        """ Converts a type ID to name. On error returns None
        """
        NAME_TYPES = {cls.TYPE_NAMES[x]: x for x in cls.TYPE_NAMES}
        return NAME_TYPES.get(typename, None)


class SCOPE(object):
    """ Enum scopes
    """
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
    """ Enum kind
    """
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

# Maps deprecated suffixes to types
SUFFIX_TYPE = {'$': TYPE.string, '%': TYPE.integer, '&': TYPE.long_}
