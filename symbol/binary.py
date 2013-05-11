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
#from libzx.global import optemps

class SymbolBINARY(Symbol):
    ''' Defines a BINARY EXPRESSION e.g. (a + b)
        Only the operator (e.g. 'PLUS') is stored.
    '''
    def __init__(self, oper, left, right, lineno):
        Symbol.__init__(self, oper)
        #self.t = optemps.new_t()
        self.lineno = lineno
        self.appendChild(right)

    @property
    def operator(self):
        return self.text

    @property
    def left(self):
        return self.children[0]        
        
    @left.setter
    def left(self, value):
        self.children[0] = value
        
    @property
    def right(self):
        return self.children[1]
        
    @right.setter
    def right(self, value):
        self.children[1] = value

    def __str__(self):
        return '%s %s %s' % (self.left, self.operator, self.right)
                
    def __repr__(self):
        return '(%s: %s %s)' % (self.operator, self.left, self.right)
