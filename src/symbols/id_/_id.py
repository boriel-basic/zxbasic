# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from __future__ import annotations

from typing import Any

from src.api import global_
from src.api.config import OPTIONS
from src.api.constants import CLASS, SCOPE
from src.symbols.boundlist import SymbolBOUNDLIST
from src.symbols.id_ import ref
from src.symbols.id_.interface import SymbolIdABC
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import SymbolTYPE

# ----------------------------------------------------------------------
# Identifier Symbol object
# ----------------------------------------------------------------------


class SymbolID(SymbolIdABC):
    """Defines an VAR (Variable) symbol.
    These class and their children classes are also stored in the symbol
    table as table entries to store variable data
    """

    __slots__ = (
        "_accessed",
        "_ref",
        "_type",
        "addr",
        "caseins",
        "declared",
        "filename",
        "has_address",
        "original_name",
        "scope_ref",
    )

    def __init__(
        self,
        name: str,
        lineno: int,
        filename: str = None,
        type_: SymbolTYPE | None = None,
        class_: CLASS = CLASS.unknown,
    ):
        super().__init__(name=name, lineno=lineno, filename=filename, type_=type_, class_=class_)
        assert class_ in (CLASS.const, CLASS.label, CLASS.var, CLASS.unknown)

        self.name = name  # This value will be modified later removing the trailing sigil ($) if used.
        self.original_name = name  # This value will always contain the original name, preserving the sigil if used
        self.filename = global_.FILENAME if filename is None else filename  # In which file was first used
        self.lineno = lineno  # In which line was first used
        self.mangled = f"{global_.MANGLE_CHR}{name}"  # This value will be overridden later
        self.declared = False  # if explicitly declared (DIM var AS <type>)
        self.type_ = type_  # if None => unknown type (yet)
        self.caseins = OPTIONS.case_insensitive  # Whether this ID is case-insensitive or not
        self.scope = SCOPE.global_  # One of 'global', 'parameter', 'local'
        self.scope_ref: Any | None = None  # TODO: type Scope | None # Scope object this ID lives in
        self.addr = None  # If not None, the address of this symbol in memory (string, cam be an expr like "_addr1 + 2")
        self._ref: ref.SymbolRef = ref.SymbolRef(self)
        self.has_address: bool | None = None  # Whether this ID exist in memory or not

        if class_ == CLASS.var:
            self.to_var()
        elif class_ == CLASS.label:
            self.to_label()

    @property
    def token(self) -> str:
        return self._ref.token

    @property
    def callable(self) -> bool | None:  # Whether this id can be followed by parenthesis. i.e. var(...)
        return self._ref.callable

    @property
    def class_(self) -> CLASS:
        return self._ref.class_

    def __str__(self):
        return self.name

    def __repr__(self):
        return repr(self._ref)

    @property
    def t(self) -> str:
        return self._ref.t

    @property
    def type_(self):
        return self._type

    @type_.setter
    def type_(self, value: SymbolTYPE | None):
        assert value is None or isinstance(value, SymbolTYPE)
        self._type = value

    @property
    def accessed(self) -> bool:
        """Whether this object has been accessed (if false it might be not compiled)"""
        return self.ref.accessed

    @accessed.setter
    def accessed(self, value: bool):
        self.ref.accessed = bool(value)

    def to_var(self, default_value: Symbol | None = None):
        """Converts an id into a variable"""
        assert self.class_ == CLASS.unknown or (
            self.class_ == CLASS.var
            and isinstance(self._ref, ref.VarRef)
            and (self._ref.default_value is None or self._ref.default_value == default_value)
        )
        assert self.has_address or self.has_address is None

        self.has_address = True

        if self.class_ == CLASS.var:
            self._ref.default_value = default_value
            return self

        old_ref = self._ref
        self._ref = ref.VarRef(self, default_value)
        self._ref.accessed = old_ref.accessed
        return self

    def to_const(self, default_value: Symbol | None):
        assert self.class_ == CLASS.unknown
        assert not self.has_address or self.has_address is None

        self.has_address = False
        self._ref = ref.ConstRef(self, default_value)
        return self

    def to_label(self):
        """Converts an id into a label"""
        assert self.class_ in (CLASS.unknown, CLASS.label)
        assert self.has_address or self.has_address is None

        self.has_address = True
        old_ref = self._ref
        self._ref = ref.LabelRef(self)
        self.accessed = old_ref.accessed
        return self

    def to_function(self, lineno: int = None, class_=CLASS.function):
        """Converts an id into a function or sub"""
        assert self.class_ == CLASS.unknown
        assert self.has_address or self.has_address is None

        self.has_address = True
        old_ref = self._ref
        self._ref = ref.FuncRef(self, lineno=lineno, class_=class_)
        self.accessed = old_ref.accessed
        return self

    def to_vararray(self, bounds: SymbolBOUNDLIST) -> SymbolID:
        """Converts an id into a var array one"""
        assert self.class_ == CLASS.unknown
        assert self.has_address or self.has_address is None

        self.has_address = True
        old_ref = self._ref
        self._ref = ref.ArrayRef(self, bounds=bounds)
        self.accessed = old_ref.accessed
        return self

    @property
    def ref(self) -> ref.SymbolRef:
        return self._ref

    def __getattr__(self, item):
        return getattr(self.ref, item)
