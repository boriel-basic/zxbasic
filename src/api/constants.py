#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------
from __future__ import annotations

import enum
import os

from src.api.decorator import classproperty
from src.api.type import PrimitiveType

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

# Maps deprecated suffixes to types
SUFFIX_TYPE = {"$": PrimitiveType.string, "%": PrimitiveType.integer, "&": PrimitiveType.long}
