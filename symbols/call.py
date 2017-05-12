#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import api.global_ as gl
from api.check import check_call_arguments
from api.constants import CLASS
import api.errmsg as errmsg

from .symbol_ import Symbol
from .function import SymbolFUNCTION
from .arglist import SymbolARGLIST
from .type_ import Type


class SymbolCALL(Symbol):
    ''' Defines function / procedure call. E.g. F(1, A + 2)
    It contains the symbol table entry of the called function (e.g. F)
    And a list of arguments. (e.g. (1, A + 2) in this example).

    Parameters:
        id_: The symbol table entry
        arglist: a SymbolArglist instance
        lineno: source code line where this call was made
    '''
    def __init__(self, entry, arglist, lineno):
        Symbol.__init__(self)
        assert isinstance(lineno, int)
        self.entry = entry
        self.args = arglist  # Func. call / array access
        self.lineno = lineno

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
    def make_node(cls, id_, params, lineno):
        ''' This will return an AST node for a function/procedure call.
        '''
        assert isinstance(params, SymbolARGLIST)
        entry = gl.SYMBOL_TABLE.access_func(id_, lineno)
        if entry is None:  # A syntax / semantic error
            return None

        if entry.callable is False:  # Is it NOT callable?
            if entry.type_ != Type.string:
                errmsg.syntax_error_not_array_nor_func(lineno, id_)
                return None

        gl.SYMBOL_TABLE.check_class(id_, CLASS.function, lineno)
        entry.accessed = True

        if entry.declared:
            check_call_arguments(lineno, id_, params)
        else:  # All functions goes to global scope (no nested functions) # TODO: Nested functions... not yet
            gl.SYMBOL_TABLE.move_to_global_scope(id_)
            gl.FUNCTION_CALLS.append((id_, params, lineno,))

        return cls(entry, params, lineno)
