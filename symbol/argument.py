#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol import Symbol
from constants import *



class Argument(Symbol):
    ''' Defines an argument in a function call
    '''
    def __init__(self, lineno, expr, byref = False):
        ''' Initializes the argument data. Byref must be set
        to True if this Argument is passed by reference.
        '''
        Symbol.__init__(self, None, 'ARGUMENT')
        self.lineno = lineno
        self.byref = byref
        self.arg = expr
    

    @property
    def child(self):
        ''' Returns child node (AST)
        '''
        return [self.arg]

    @property
    def _type(self):
        return self.arg._type

    @property
    def size(self):
        return TYPE_SIZES[self._type]

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
        self.this.next[0] = make_typecast(_type, self.this.next[0])

        return self.this.next[0] is not None


