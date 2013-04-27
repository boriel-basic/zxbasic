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


class SymbolARRAYDECL(Symbol):
    ''' Defines an Array declaration
    '''
    def __init__(self, symbol):
        Symbol.__init__(self, symbol._mangled, 'ARRAYDECL')
        self._type = symbol._type
        self.size = symbol.total_size # Total array cell + index size
        self.entry = symbol
        self.bounds = symbol.bounds

