#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.check import is_null
from .symbol_ import Symbol


class SymbolBLOCK(Symbol):
    ''' Defines a block of code.
    '''
    def __init__(self, *nodes):
        Symbol.__init__(self, *(x for x in nodes if not is_null(x)))

    @classmethod
    def make_node(cls, *args):
        ''' Creates a chain of code blocks.
        '''
        args = [x for x in args if not is_null(x)]
        if not args:
            return SymbolBLOCK()  # Empty block

        for x in args:
            assert isinstance(x, Symbol)

        if args[0].token == 'BLOCK':
            args = args[0].children + args[1:]

        if args and args[-1].token == 'BLOCK':
            args = args[:-1] + args[-1].children

        result = SymbolBLOCK(*tuple(args))
        return result

    def __getitem__(self, item):
        return self.children[item]

    def __len__(self):
        return len(self.children)

    def __eq__(self, other):
        if not isinstance(other, SymbolBLOCK):
            return False

        return len(self) == len(other) and all([x == y for x, y in zip(self, other)])

    def __hash__(self):
        return id(self)
