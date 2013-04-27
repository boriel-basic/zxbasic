#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from constants import TYPE_SIZES
from symbol import Symbol
from typecast import make_typecast


class SymbolARGUMENT(Symbol):
    ''' Defines an argument in a function call
    '''
    def __init__(self, lineno, byref = False):
        ''' Initializes the argument data. Byref must be set
        to True if this Argument is passed by reference.
        '''
        Symbol.__init__(self, None, 'ARGUMENT')
        self.lineno = lineno
        self.byref = byref

    @property
    def _type(self):
        return self.arg._type

    @property
    def size(self):
        return TYPE_SIZES[self._type]

    @property
    def arg(self):
        return self.this.next[0].symbol # The argument itself (SymbolID, SymbolBINARY, etc...)

    @property
    def t(self):
        return self.arg.t

    @property
    def _mangled(self):
        return self.arg._mangled

    def typecast(self, _type):
        ''' Apply type casting to the argument expression.
        Returns True on success.
        '''
        self.this.next[0] = make_typecast(_type, self.this.next[0], self.lineno)

        return self.this.next[0] is not None

