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


class SymbolTYPECAST(Symbol):
    ''' Defines a typecast operation.
    '''
    def __init__(self, new_type):
        Symbol.__init__(self, new_type, 'CAST')
        self.t = optemps.new_t()
        self._type = new_type

