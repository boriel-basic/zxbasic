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


class SymbolSTRSLICE(Symbol):
    ''' Defines a string slice
    '''
    def __init__(self, string, lower, upper, lineno):
        Symbol.__init__(self, string, lower, upper)
        self.lineno = lineno
        self.type_ = 'string'

    @property
    def string(self):
        return self.children[0]

    @string.setter
    def string(self, value):
        self.children[0] = value
        
    @property
    def lower(self):
        return self.children[1]
       
    @lower.setter
    def lower(self, value):
        self.children[1] = value
        
    @property
    def upper(self):
        return self.children[2]
        
    @upper.setter
    def upper(self, value):
        self.children[2] = value
    

'''    @classmethod
    def 
    
    '''
    