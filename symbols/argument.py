#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.constants import TYPE_SIZES
from symbol_ import Symbol
from typecast import SymbolTYPECAST
from api.config import OPTIONS


class SymbolARGUMENT(Symbol):
    ''' Defines an argument in a function call
    '''
    def __init__(self, value, lineno, byref=None):
        ''' Initializes the argument data. Byref must be set
        to True if this Argument is passed by reference.
        '''
        Symbol.__init__(self, value)
        self.lineno = lineno
        self.byref = byref if byref is not None else OPTIONS.byref.value

    @property
    def value(self):
        return self.children[0]

    @value.setter
    def value(self, val):
        self.children[0] = val

    @property
    def type_(self):
        return self.value.type_

    @property
    def class_(self):
        return self.value.class_

    @property
    def size(self):
        return TYPE_SIZES[self.type_]

    def typecast(self, type_):
        ''' Test type casting to the argument expression.
        On sucess changes the node value to the new typecast, and returns
        True. On failure, returns False, and the node value is set to None.
        '''
        self.value = SymbolTYPECAST.make_node(type_, self.value, self.lineno)
        return self.value is not None
