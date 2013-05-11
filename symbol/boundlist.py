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


class SymbolBOUNDLIST(Symbol):
    ''' Defines a bound list for an array
    '''
    def __init__(self):
        Symbol.__init__(self)

    def __len__(self): # Number of bounds:
        return len(self.children)
  
    @property
    def count(self):
        ''' Total number of array cells
        '''
        return sum(x.count for x in self.children)

    def __getitem__(self, key):
        return self.children[key]
               
    def __str__(self):
        return '(%s)' % ', '.join(x for x in self.children)        