#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from obj.gl import optemps
from symbol import Symbol


class SymbolCALL(Symbol):
    ''' Defines a list of arguments in a function call/array access/string
    '''
    def __init__(self, lineno, symbol, name = 'FUNCCALL'):
        Symbol.__init__(self, symbol._mangled, name) # Func. call / array access
        self.entry = symbol
        self.t = optemps.new_t()
        self.lineno = lineno

    @property
    def _type(self):
        return self.entry._type

    @property
    def size(self):
        return TYPE_SIZES[self._type]

    @property
    def args(self):
        return self.this.next[0].symbol


