#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol import Symbol

class SymbolUNARY(Symbol):
    ''' Defines an UNARY EXPRESSION e.g. (a + b)
        Only the operator (e.g. 'PLUS') is stored.
    '''
    def __init__(self, oper, operand, lineno):
        Symbol.__init__(self, operand)
        self.lineno = lineno
        self.operator = operator
        
    @property
    def operand(self):
        return self.children[0]
        
    @operand.setter
    def operand(self, value):
        self.children[0] = value      

    def __str__(self):
        return '%s%s' % (self.operator, self.operand)
                
    def __repr__(self):
        return '(%s: %s)' % (self.operator, self.operand)