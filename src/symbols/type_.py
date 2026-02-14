# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------
from __future__ import annotations

from typing import Any, Final

from src.api import global_ as gl
from src.api.config import OPTIONS
from src.api.constants import CLASS, TYPE
from src.api.decorator import classproperty

from .symbol_ import Symbol

__all__: Final[tuple[str]] = "SymbolTYPE", "SymbolBASICTYPE", "SymbolTYPEALIAS", "SymbolTYPEREF", "Type"


class SymbolTYPE(Symbol):
    """A Type definition. Defines a type,
    both user-defined or basic ones.
    """

    def __init__(self, name: str, namespace: str, size: int, lineno: int, filename: str = ""):
        # All children (if any) must be SymbolTYPE
        super().__init__()
        self.name = name  # typename
        self.namespace = namespace  # Namespace where this type was defined
        self._size = size
        self.lineno = lineno  # The line the type was defined. Line 0 = basic type
        self.caseins = OPTIONS.case_insensitive  # Whether this ID is case-insensitive or not
        self.class_ = CLASS.type
        self.accessed = False  # Whether this type has been used or not
        self.filename = filename or gl.FILENAME  # Filename where this type was defined

    def __repr__(self):
        return "%s(%s)" % (self.token, str(self))

    def __str__(self):
        return self.name

    def __hash__(self):
        return id(self)

    @property
    def final(self) -> SymbolTYPE:
        """For any aliased type, return the final type."""
        return self

    @property
    def canonical_name(self) -> str:
        canonical_name = f"{self.namespace}{gl.NAMESPACE_SEPARATOR}{self.name}"
        return canonical_name.lower() if self.caseins else canonical_name

    @property
    def is_primitive(self) -> bool:
        """Whether this is a primitive type or not."""
        return True  # Subclasses must override this

    @property
    def size(self) -> int:
        return self._size

    @property
    def is_basic(self) -> bool:
        """Whether this is a basic (canonical) type or not."""
        return False

    @property
    def is_alias(self) -> bool:
        """Whether this is an alias of another type or not."""
        return False

    @property
    def is_dynamic(self) -> bool:
        """Whether this type is dynamic in memory (allocated in the HEAP)."""
        return False

    def __eq__(self, other: Any) -> bool:
        """Nominal equality"""
        if not isinstance(other, SymbolTYPE):
            return NotImplemented

        return self.canonical_name == other.canonical_name


class SymbolBASICTYPE(SymbolTYPE):
    """Defines a basic type (Ubyte, Byte, etc.)
    Basic (default) types are defined upon start and are case-insensitive.
    """

    TYPES: Final[dict[TYPE, SymbolBASICTYPE]] = {}

    def __init__(self, type_: TYPE):
        """type_ = Internal representation (e.g. TYPE.ubyte)"""
        assert TYPE.is_valid(type_)
        name = TYPE.to_string(type_)

        super().__init__(name=name, size=TYPE.size(type_), namespace="", lineno=0, filename="<internal>")
        self._type = type_

    def __new__(cls, *args, **kwargs) -> SymbolBASICTYPE:
        """Ensures the same basic type is returned for the same TYPE
        if it's already been created."""
        return cls.TYPES.setdefault(args[0], super().__new__(cls))

    @property
    def is_basic(self) -> bool:
        """Whether this is a basic (canonical) type or not."""
        return True

    @property
    def is_signed(self) -> bool:
        return TYPE.is_signed(self._type)

    def to_signed(self):
        """Returns another instance with the signed equivalent
        of this type.
        """
        return SymbolBASICTYPE(TYPE.to_signed(self._type))

    @property
    def is_dynamic(self) -> bool:
        return self._type == TYPE.string

    def __bool__(self) -> bool:
        return self._type != TYPE.unknown


class SymbolTYPEALIAS(SymbolTYPE):
    """Defines a type which is an alias of another"""

    def __init__(self, name: str, namespace: str, alias: SymbolTYPE, lineno: int, filename: str = ""):
        assert isinstance(alias, SymbolTYPE)
        filename = filename or gl.FILENAME
        super().__init__(name=name, namespace=namespace, lineno=lineno, size=alias.size, filename=filename)
        self._base = alias

    @property
    def is_alias(self) -> bool:
        """Whether this is an alias of another type or not."""
        return True

    @property
    def final(self) -> SymbolTYPE:
        return self._base.final

    @property
    def is_basic(self) -> bool:
        return self._base.is_basic

    @property
    def base(self) -> SymbolTYPE:
        return self._base

    @property
    def to_signed(self):
        assert self.is_basic
        return self._base.to_signed()

    @property
    def is_dynamic(self) -> bool:
        return self._base.is_dynamic


class SymbolTYPEREF(Symbol):
    """
    Describes a Type annotation (file, line number).
       Eg. DIM a As Integer
    In this case, the variable a is annotated with the type Integer.
    """

    def __init__(self, type_: SymbolTYPE, lineno: int, filename: str = "", *, implicit: bool = False):
        assert isinstance(type_, SymbolTYPE)
        super().__init__(type_)
        self.implicit = implicit  # Whether this annotation was implicit or not
        self.lineno = lineno  # Line number where this annotation was defined
        self.filename = filename or gl.FILENAME  # Filename where this annotation was defined

    @property
    def type_(self) -> SymbolTYPE:
        return self.children[0]

    @property
    def name(self) -> str:
        return self.type_.name

    @property
    def size(self) -> int:
        return self.type_.size

    def to_signed(self):
        type_ = self.type_
        assert isinstance(type_, SymbolBASICTYPE)
        return type_.to_signed()

    @property
    def is_basic(self) -> bool:
        return self.type_.is_basic

    @property
    def is_dynamic(self) -> bool:
        return self.type_.is_dynamic

    @property
    def final(self) -> SymbolTYPE:
        return self.type_.final

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, SymbolTYPEREF | SymbolTYPE):
            raise NotImplementedError(f"Invalid operand '{other}':{type(other)}")

        if isinstance(other, SymbolTYPEREF):
            return self.type_ == other.type_

        return self.type_ == other


class Type:
    """Class for enumerating Basic Types.
    e.g. Type.string.
    """

    unknown = auto = SymbolBASICTYPE(TYPE.unknown)
    ubyte = SymbolBASICTYPE(TYPE.ubyte)
    byte_ = SymbolBASICTYPE(TYPE.byte)
    uinteger = SymbolBASICTYPE(TYPE.uinteger)
    long_ = SymbolBASICTYPE(TYPE.long)
    ulong = SymbolBASICTYPE(TYPE.ulong)
    integer = SymbolBASICTYPE(TYPE.integer)
    fixed = SymbolBASICTYPE(TYPE.fixed)
    float_ = SymbolBASICTYPE(TYPE.float)
    string = SymbolBASICTYPE(TYPE.string)
    boolean = SymbolBASICTYPE(TYPE.boolean)

    types = unknown, ubyte, byte_, uinteger, integer, ulong, long_, fixed, float_, string, boolean

    _by_name = {x.name: x for x in types}

    @classmethod
    def size(cls, t: SymbolTYPE) -> int:
        return t.size

    @classmethod
    def to_string(cls, t: SymbolTYPE) -> str:
        return t.name

    @classmethod
    def by_name(cls, typename) -> SymbolBASICTYPE | None:
        """Converts a given typename to Type"""
        return cls._by_name.get(typename, None)

    @classproperty
    def integrals(cls) -> set[SymbolBASICTYPE]:
        return {cls.boolean, cls.byte_, cls.ubyte, cls.integer, cls.uinteger, cls.long_, cls.ulong}

    @classproperty
    def signed(cls) -> set[SymbolBASICTYPE]:
        return {cls.byte_, cls.integer, cls.long_, cls.fixed, cls.float_}

    @classproperty
    def unsigned(cls) -> set[SymbolBASICTYPE]:
        return {cls.boolean, cls.ubyte, cls.uinteger, cls.ulong}

    @classproperty
    def decimals(cls) -> set[SymbolBASICTYPE]:
        return {cls.fixed, cls.float_}

    @classproperty
    def numbers(cls) -> set[SymbolBASICTYPE]:
        return cls.integrals | cls.decimals

    @classmethod
    def is_numeric(cls, t: SymbolTYPE) -> bool:
        assert isinstance(t, SymbolTYPE)
        return t.is_basic and t.final in cls.numbers

    @classmethod
    def is_signed(cls, t: SymbolTYPE) -> bool:
        assert isinstance(t, SymbolTYPE)
        return t.is_basic and t.final in cls.signed

    @classmethod
    def is_unsigned(cls, t: SymbolTYPE) -> bool:
        assert isinstance(t, SymbolTYPE)
        return t.is_basic and t.final in cls.unsigned

    @classmethod
    def is_integral(cls, t: SymbolTYPE) -> bool:
        assert isinstance(t, SymbolTYPE)
        return t.is_basic and t.final in cls.integrals

    @classmethod
    def is_decimal(cls, t: SymbolTYPE) -> bool:
        assert isinstance(t, SymbolTYPE)
        return t.is_basic and t.final in cls.decimals

    @classmethod
    def is_string(cls, t: SymbolTYPE) -> bool:
        assert isinstance(t, SymbolTYPE)
        return t.final == cls.string

    @classmethod
    def to_signed(cls, t: SymbolTYPE):
        """Return signed type or equivalent"""
        assert isinstance(t, SymbolTYPE)
        if not isinstance(t, SymbolBASICTYPE):
            return cls.unknown

        if cls.is_unsigned(t):
            return {cls.boolean: cls.byte_, cls.ubyte: cls.byte_, cls.uinteger: cls.integer, cls.ulong: cls.long_}[t]

        if cls.is_signed(t) or cls.is_decimal(t):
            return t

        return cls.unknown
