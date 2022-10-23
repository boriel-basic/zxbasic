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

from src.api.constants import CLASS, CONVENTION
from src.symbols.block import SymbolBLOCK
from src.symbols.id_ import SymbolID
from src.symbols.paramlist import SymbolPARAMLIST
from src.symbols.type_ import SymbolTYPE


class SymbolFUNCTION(SymbolID):
    """This class expands VAR top denote Function declarations"""

    local_symbol_table = None
    convention: CONVENTION
    callable: bool
    forwarded: bool

    def __init__(
        self,
        name: str,
        lineno: int,
        filename: str = None,
        type_: Optional[SymbolTYPE] = None,
        class_: CLASS = CLASS.unknown,
    ):
        super().__init__(name=name, lineno=lineno, filename=filename, type_=type_)
        assert class_ in {CLASS.unknown, CLASS.function, CLASS.sub}
        self._class = class_
        self.reset()

    def reset(self, lineno=None, type_=None):
        """This is called when we need to reinitialize the instance state"""
        self.lineno = self.lineno if lineno is None else lineno
        self.type_ = self.type_ if type_ is None else type_
        self.callable = True
        self.params = SymbolPARAMLIST()
        self.body = SymbolBLOCK()
        self.local_symbol_table = None
        self.convention = CONVENTION.unknown
        self.forwarded = False  # True if declared (with DECLARE) in advance (functions or subs)

    @property
    def params(self) -> SymbolPARAMLIST:
        if not self.children:
            return SymbolPARAMLIST()
        return self.children[0]

    @params.setter
    def params(self, value: SymbolPARAMLIST):
        assert isinstance(value, SymbolPARAMLIST)
        if self.children is None:
            self.children = []

        if self.children:
            self.children[0] = value
        else:
            self.children = [value]

    @property
    def body(self) -> SymbolBLOCK:
        if not self.children or len(self.children) < 2:
            self.body = SymbolBLOCK()

        return self.children[1]

    @body.setter
    def body(self, value: Optional[SymbolBLOCK]):
        if value is None:
            value = SymbolBLOCK()
        assert isinstance(value, SymbolBLOCK)

        if self.children is None:
            self.children = []

        if not self.children:
            self.params = SymbolPARAMLIST()

        if len(self.children) < 2:
            self.children.append(value)
        else:
            self.children[1] = value

    def __repr__(self):
        return f"FUNC:{self.name}"

    @property
    def t(self):
        return self.mangled
