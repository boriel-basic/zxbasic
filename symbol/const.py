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

# ----------------------------------------------------------------------
# CONST Symbol object
# ----------------------------------------------------------------------

class SymbolCONST(Symbol):
    ''' Defines a constant expression (not numerical, e.g. a Label or an @label)
    '''
    def __init__(self, expr, lineno):
        Symbol.__init__(self, expr)
        self.lineno = lineno

    @property
    def expr(self):
        return self.children[0]
        
    @expr.setter
    def expr(self, value):
        self.children[0] = value

    @property
    def type_(self):
        return self.expr.type_
        
    def __str__(self):
        return str(self.expr)

    def __repr__(self):
        return str(self)
