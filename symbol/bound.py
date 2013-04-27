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


class SymbolBOUND(Symbol):
    ''' Defines an array bound
    '''
    def __init__(self, lower, upper):
        Symbol.__init__(self, None, 'BOUND')
        self.lower = lower
        self.upper = upper
        self.size = upper - lower + 1

