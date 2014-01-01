#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol_ import Symbol


class SymbolBLOCK(Symbol):
    ''' Defines a block of code.
    '''
    def __init__(self, *nodes):
        Symbol.__init__(self, *nodes)

    @classmethod
    def make_node(clss, *args):
        ''' Creates a chain of code blocks.
        '''
        args = [x for x in args if x is not None]
        if not args:
            return None

        if args[0].token == 'BLOCK':
            args = args[0].children + args[1:]

        if args[-1].token == 'BLOCK':
            args = args[:-1] + args[-1].children

        return SymbolBLOCK(*tuple(args))


    def __getitem__(self, item):
        return self.children[item]
