#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import enum
import os
from typing import Optional, Union

from .decorator import classproperty

# -------------------------------------------------
# Global constants
# -------------------------------------------------

# Path to main ZX Basic compiler executable
ZXBASIC_ROOT = os.path.abspath(
    os.path.join(os.path.abspath(os.path.dirname(os.path.abspath(__file__))), os.path.pardir)
)


# ----------------------------------------------------------------------
# Class enums
# ----------------------------------------------------------------------


@enum.unique
class CLASS(str, enum.Enum):
    """Enums class constants"""

    unknown = "unknown"  # 0
    var = "var"  # 1  # scalar variable
    array = "array"  # 2  # array variable
    function = "function"  # 3  # function
    label = "label"  # 4 Labels
    const = "const"  # 5  # constant literal value e.g. 5 or "AB"
    sub = "sub"  # 6  # subroutine
    type = "type"  # 7  # type

    @classproperty
    def classes(cls):
        return cls.unknown, cls.var, cls.array, cls.function, cls.sub, cls.const, cls.label

    @classmethod
    def is_valid(cls, class_: Union[str, "CLASS"]):
        """Whether the given class is
        valid or not.
        """
        return class_ in set(CLASS)

    @classmethod
    def to_string(cls, class_: "CLASS"):
        assert cls.is_valid(class_)
        return class_.value


class ARRAY:
    """Enums array constants"""

    bound_size = 2  # This might change depending on arch, program, etc..
    bound_count = 2  # Size of bounds counter
    array_type_size = 1  # Size of array type


@enum.unique
class TYPE(enum.IntEnum):
    """Enums primary type constants"""

    unknown = 0
    byte = 1
    ubyte = 2
    integer = 3
    uinteger = 4
    long = 5
    ulong = 6
    fixed = 7
    float = 8
    string = 9

    @classmethod
    def type_size(cls, type_: "TYPE"):
        type_sizes = {
            cls.byte: 1,
            cls.ubyte: 1,
            cls.integer: 2,
            cls.uinteger: 2,
            cls.long: 4,
            cls.ulong: 4,
            cls.fixed: 4,
            cls.float: 5,
            cls.string: 2,
            cls.unknown: 0,
        }
        return type_sizes[type_]

    @classproperty
    def types(cls):
        return set(TYPE)

    @classmethod
    def size(cls, type_: "TYPE"):
        return cls.type_size(type_)

    @classproperty
    def integral(cls):
        return {cls.byte, cls.ubyte, cls.integer, cls.uinteger, cls.long, cls.ulong}

    @classproperty
    def signed(cls):
        return {cls.byte, cls.integer, cls.long, cls.fixed, cls.float}

    @classproperty
    def unsigned(cls):
        return {cls.ubyte, cls.uinteger, cls.ulong}

    @classproperty
    def decimals(cls):
        return {cls.fixed, cls.float}

    @classproperty
    def numbers(cls):
        return set(cls.integral) | set(cls.decimals)

    @classmethod
    def is_valid(cls, type_: "TYPE"):
        """Whether the given type is
        valid or not.
        """
        return type_ in cls.types

    @classmethod
    def is_signed(cls, type_: "TYPE"):
        return type_ in cls.signed

    @classmethod
    def is_unsigned(cls, type_: "TYPE"):
        return type_ in cls.unsigned

    @classmethod
    def to_signed(cls, type_: "TYPE"):
        """Return signed type or equivalent"""
        if type_ in cls.unsigned:
            return {TYPE.ubyte: TYPE.byte, TYPE.uinteger: TYPE.integer, TYPE.ulong: TYPE.long}[type_]
        if type_ in cls.decimals or type_ in cls.signed:
            return type_
        return cls.unknown

    @staticmethod
    def to_string(type_: "TYPE"):
        """Return ID representation (string) of a type"""
        return type_.name

    @staticmethod
    def to_type(typename: str) -> Optional["TYPE"]:
        """Converts a type ID to name. On error returns None"""
        for t in TYPE:
            if t.name == typename:
                return t

        return None


@enum.unique
class SCOPE(str, enum.Enum):
    """Enum scopes"""

    global_ = "global"
    local = "local"
    parameter = "parameter"

    @staticmethod
    def is_valid(scope: Union[str, "SCOPE"]):
        return scope in set(SCOPE)

    @staticmethod
    def to_string(scope: "SCOPE"):
        assert SCOPE.is_valid(scope)
        return scope.value


@enum.unique
class CONVENTION(str, enum.Enum):
    unknown = "unknown"
    fastcall = "__fastcall__"
    stdcall = "__stdcall__"

    @staticmethod
    def is_valid(convention: Union[str, "CONVENTION"]):
        return convention in set(CONVENTION)

    @staticmethod
    def to_string(convention: "CONVENTION"):
        assert CONVENTION.is_valid(convention)
        return convention.value


@enum.unique
class LoopType(str, enum.Enum):
    DO = "DO"
    FOR = "FOR"
    WHILE = "WHILE"


# ----------------------------------------------------------------------
# Deprecated suffixes for variable names, such as "a$"
# ----------------------------------------------------------------------
DEPRECATED_SUFFIXES = ("$", "%", "&")

# ----------------------------------------------------------------------
# Identifier type
# i8 = Integer, 8 bits
# u8 = Unsigned, 8 bits and so on
# ----------------------------------------------------------------------
ID_TYPES = TYPE.types

# Maps deprecated suffixes to types
SUFFIX_TYPE = {"$": TYPE.string, "%": TYPE.integer, "&": TYPE.long}
