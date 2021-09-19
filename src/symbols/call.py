#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from typing import Iterable
from typing import Optional

import src.api.check as check
import src.api.errmsg as errmsg
import src.api.global_ as gl

from .symbol_ import Symbol
from .function import SymbolFUNCTION
from .arglist import SymbolARGLIST
from .argument import SymbolARGUMENT
from .var import SymbolVAR
from .type_ import Type


class SymbolCALL(Symbol):
    """Defines function / procedure call. E.g. F(1, A + 2)
    It contains the symbol table entry of the called function (e.g. F)
    And a list of arguments. (e.g. (1, A + 2) in this example).

    Parameters:
        id_: The symbol table entry
        arglist: a SymbolARGLIST instance
        lineno: source code line where this call was made
    """

    entry: SymbolFUNCTION

    def __init__(self, entry: Symbol, arglist: Iterable[SymbolARGUMENT], lineno: int, filename: str):
        super().__init__()
        assert isinstance(lineno, int)
        assert all(isinstance(x, SymbolARGUMENT) for x in arglist)
        self.entry = entry
        self.args = arglist  # Func. call / array access
        self.lineno = lineno
        self.filename = filename

        if isinstance(entry, SymbolFUNCTION):  # TODO: This condition is always True? If so => assert it
            for arg, param in zip(arglist, entry.params):  # Sets dependency graph for each argument -> parameter
                if arg.value is not None:
                    arg.value.add_required_symbol(param)

    @property
    def entry(self):
        return self.children[0]

    @entry.setter
    def entry(self, value):
        assert isinstance(value, SymbolFUNCTION)
        if self.children is None or not self.children:
            self.children = [value]
        else:
            self.children[0] = value

    @property
    def args(self):
        return self.children[1]

    @args.setter
    def args(self, value):
        assert isinstance(value, SymbolARGLIST)
        if self.children is None or not self.children:
            self.children = [None]

        if len(self.children) < 2:
            self.children.append(value)
            return

        self.children[1] = value

    @property
    def type_(self):
        return self.entry.type_

    @classmethod
    def make_node(cls, id_: str, params, lineno: int, filename: str) -> Optional["SymbolCALL"]:
        """This will return an AST node for a function/procedure call."""
        assert isinstance(params, SymbolARGLIST)
        entry = gl.SYMBOL_TABLE.access_func(id_, lineno)
        if entry is None:  # A syntax / semantic error
            return None

        if entry.callable is False:  # Is it NOT callable?
            if entry.type_ != Type.string:
                errmsg.syntax_error_not_array_nor_func(lineno, id_)
                return None

        if entry.declared and not entry.forwarded:
            check.check_call_arguments(lineno, id_, params)
        else:  # All functions goes to global scope by default
            if not isinstance(entry, SymbolFUNCTION):
                entry = SymbolVAR.to_function(entry, lineno)
            gl.SYMBOL_TABLE.move_to_global_scope(id_)
            gl.FUNCTION_CALLS.append(
                (
                    id_,
                    params,
                    lineno,
                )
            )

        return cls(entry, params, lineno, filename)
