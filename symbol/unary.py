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

class SymbolUNARY(Symbol):
    ''' Defines an UNARY EXPRESSION e.g. (a + b)
        Only the operator (e.g. 'PLUS') is stored.
    '''
    def __init__(self, oper, lineno):
        Symbol.__init__(self, oper, 'UNARY')
        self.left = None # Must be set by make_unary
        self.t = optemps.new_t()
        self.lineno = lineno

