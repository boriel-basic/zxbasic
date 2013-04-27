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
    def __init__(self, lineno, expr):
        Symbol.__init__(self, None, 'CONST')
        self.expr = expr
        self.lineno = lineno

    @property
    def _type(self):
        return self.expr._type

