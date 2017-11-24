#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License v3
# ----------------------------------------------------------------------

from api.check import is_null
from .symbol_ import Symbol


class SymbolBLOCK(Symbol):
    """ Defines a block of code.
    """
    def __init__(self, *nodes):
        super(SymbolBLOCK, self).__init__(*(x for x in nodes if not is_null(x)))

    @classmethod
    def make_node(cls, *args):
        """ Creates a chain of code blocks.
        """
        new_args = []

        args = [x for x in args if not is_null(x)]
        for x in args:
            assert isinstance(x, Symbol)
            if x.token == 'BLOCK':
                new_args.extend(SymbolBLOCK.make_node(*x.children).children)
            else:
                new_args.append(x)

        result = SymbolBLOCK(*new_args)
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
