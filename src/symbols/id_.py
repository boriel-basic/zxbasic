#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from typing import Optional

from src.api import global_
from src.api.config import OPTIONS
from src.api.constants import CLASS, SCOPE

from .symbol_ import Symbol
from .type_ import SymbolTYPE

# ----------------------------------------------------------------------
# Identifier Symbol object
# ----------------------------------------------------------------------


class SymbolID(Symbol):
    """Defines an VAR (Variable) symbol.
    These class and their children classes are also stored in the symbol
    table as table entries to store variable data
    """

    _class: CLASS = CLASS.unknown
    _ref: Symbol

    def __init__(self, name: str, lineno: int, filename: str = None, type_: Optional[SymbolTYPE] = None):
        super().__init__()

        self.name = name
        self.filename = global_.FILENAME if filename is None else filename  # In which file was first used
        self.lineno = lineno  # In which line was first used
        self.mangled = "%s%s" % (global_.MANGLE_CHR, name)  # This value will be overridden later
        self.declared = False  # if explicitly declared (DIM var AS <type>)
        self.type_ = type_  # if None => unknown type (yet)
        self._accessed = False  # Where this object has been accessed (if false it might be not compiled)
        self.caseins = OPTIONS.case_insensitive  # Whether this ID is case-insensitive or not
        self._t = global_.optemps.new_t()
        self.scope = SCOPE.global_  # One of 'global', 'parameter', 'local'
        self.scope_ref = None  # Must be set by the Symbol Table. Scope object this id lives in
        self.addr = None  # If not None, the address of this symbol in memory (string, cam be an expr like "_addr1 + 2")

    @property
    def size(self):
        if self.type_ is None:
            return 0
        return self.type_.size

    @property
    def class_(self) -> CLASS:
        return self._class

    @class_.setter
    def class_(self, value: CLASS):
        assert isinstance(value, CLASS) and CLASS.is_valid(value)
        assert self._class == CLASS.unknown or self._class == value
        self._class = value

    def __str__(self):
        return self.name

    def __repr__(self):
        return "ID:%s" % str(self)

    @property
    def type_(self):
        return self._type

    @type_.setter
    def type_(self, value: Optional[SymbolTYPE]):
        assert value is None or isinstance(value, SymbolTYPE)
        self._type = value

    @property
    def accessed(self):
        return self._accessed

    @accessed.setter
    def accessed(self, value):
        self._accessed = bool(value)
