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


class SymbolVARDECL(Symbol):
    ''' Defines a Variable declaration
    '''
    def __init__(self, symbol):
        Symbol.__init__(self, symbol._mangled, 'VARDECL')
        self._type = symbol._type
        self.size = symbol.size
        self.entry = symbol

    @property
    def default_value(self):
        return self.entry.default_value


