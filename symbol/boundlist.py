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
        Symbol.__init__(self, None, 'BOUNDLIST')
        self.size = 0  # Total number of array cells
        self.count = 0 # Number of bounds

