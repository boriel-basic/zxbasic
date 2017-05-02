#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .symbol_ import Symbol
from .bound import SymbolBOUND


class SymbolBOUNDLIST(Symbol):
    ''' Defines a bound list for an array
    '''
    def __init__(self, *bounds):
        for bound in bounds:
            assert isinstance(bound, SymbolBOUND)

        Symbol.__init__(self, *bounds)

    def __len__(self):  # Number of bounds:
        return len(self.children)

    def __getitem__(self, key):
        return self.children[key]

    def __str__(self):
        return '(%s)' % ', '.join(str(x) for x in self)

    @classmethod
    def make_node(cls, node, *args):
        ''' Creates an array BOUND LIST.
        '''
        if node is None:
            return cls.make_node(SymbolBOUNDLIST(), *args)

        if node.token != 'BOUNDLIST':
            return cls.make_node(None, node, *args)

        for arg in args:
            if arg is None:
                continue
            node.appendChild(arg)

        return node
