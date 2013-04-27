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


class SymbolPARAMLIST(Symbol):
    ''' Defines a list of parameters definitions in a function header
    '''
    def __init__(self):
        Symbol.__init__(self, None, 'PARAMLIST')
        self.size = 0   # Will contain the sum of all the params size (byte params counts as 2 bytes)
        self.count = 0    # Counter of number of params


