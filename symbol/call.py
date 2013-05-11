#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol import Symbol
from api.global_ import SYMBOL_TABLE
from api.global_ import FUNCTION_CALLS
from api.check import check_call_arguments


class SymbolCALL(Symbol):
    ''' Defines function call. E.g. F(1, A + 2)
    It contains the symbol table entry of the called function (e.g. F)
    And a list of arguments. (e.g. (1, A + 2) in this example).

    Parameters:
        id_: The symbol table entry
        arglist: a SymbolArglist instance
        lineno: source code line where this call was made
    '''
    def __init__(self, entry, arglist, lineno):
        Symbol.__init__(self, entry, arglist)  # Func. call / array access
        self.lineno = lineno

    @property
    def entry(self):
        return self.children[0]

    @property
    def args(self):
        return self.children[1]

    @property
    def type_(self):
        return self.entry.type_

    @classmethod
    def make_node(clss, id_, lineno, params):
        ''' This will return an AST node for a function/procedure call.
        '''
        entry = SYMBOL_TABLE.make_callable(id_, lineno)
        if entry.class_ is None:
            entry.class_ = 'function'

        entry.accessed = True
        SYMBOL_TABLE.check_class(id_, 'function', lineno)

        if entry.declared:
            check_call_arguments(lineno, id_, params)
        else:  # All functions goes to global scope (no nested functions)
            SYMBOL_TABLE.move_to_global_scope(id_)
            FUNCTION_CALLS.append((id_, params, lineno,))

        return clss(entry, params, lineno)
