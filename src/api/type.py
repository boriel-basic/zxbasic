# -*- coding: utf-8 -*-

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from __future__ import annotations
from enum import Enum
from typing import NamedTuple
from dataclasses import dataclass

__all__ = "ArrayType", "PrimitiveType", "StructType", "Type"


class BasicType(NamedTuple):
    """In BASIC primitive types are:
    - NIL  (equivalent to null in other languages)
    - Byte | Ubyte (equivalent to int8 / uint8)
    - Integer | UInteger (equivalent to int16 / uint16)
    - Long | ULong (equivalent to i32,
    - Float
    - Strings
    - Boolean
    - Unknown
    """

    name: str
    size: int | None = None  # Size in bytes


class PrimitiveType(BasicType, Enum):
    unknown = BasicType("unknown")
    nil = BasicType("nil")
    bool = BasicType("bool", 1)
    byte = BasicType("int8", 1)
    uByte = BasicType("uint8", 1)
    integer = BasicType("int16", 2)
    uInteger = BasicType("uint16", 2)
    long = BasicType("int32", 4)
    uLong = BasicType("uint32", 4)
    float = BasicType("float", 5)
    string = BasicType("str", 2)


@dataclass(frozen=True)
class ArrayType:
    type: Type

    def __eq__(self, other):
        return isinstance(other, ArrayType) and self.type == other.type

    @property
    def size(self) -> int:
        return self.type.size


@dataclass(frozen=True)
class _StructFieldType:
    """The field of a struct."""

    name: str
    type: Type

    def __eq__(self, other):
        return isinstance(other, _StructFieldType) and self.type == other.type

    @property
    def size(self) -> int:
        return self.type.size


@dataclass(frozen=True)
class StructType:
    fields: tuple[_StructFieldType, ...]

    def __eq__(self, other):
        return isinstance(other, StructType) and self.fields == other.fields

    @property
    def size(self) -> int:
        return sum(field.size for field in self.fields)


Type = PrimitiveType | ArrayType | StructType
TypeInstance = PrimitiveType, ArrayType, StructType  # Used in isinstance
