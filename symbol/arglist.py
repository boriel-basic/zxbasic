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


class SymbolARGLIST(Symbol):
    ''' Defines a list of arguments in a function call
    '''
    def __init__(self):
        Symbol.__init__(self, None, 'ARGLIST')
        self.count = 0 # Number of params

    def __getitem__(self, range):
        return self.this.next[range]

