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


class SymbolSTRSLICE(Symbol):
    ''' Defines a string slice
    '''
    def __init__(self, lineno):
        Symbol.__init__(self, None, 'STRSLICE')
        self.lineno = lineno
        self._type = 'string'
        self.t = optemps.new_t()

