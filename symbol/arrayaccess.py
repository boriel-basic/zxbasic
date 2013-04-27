#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from call import SymbolCALL

class SymbolARRAYACCESS(SymbolCALL):
    ''' Defines an array access. It's pretty much like a function call
    (e.g. A(1, 2) could be an array access or a function call, depending on
    context). So we derive this class from SymbolCall

    Initializing this with SymbolArrayAccess(symbol, ARRAYLOAD) will
    make the returned expression to be loaded into the stack (by default
    it only returns the pointer address to the element)
    '''
    def __init__(self, lineno, symbol, access = 'ARRAYACCESS', offset = None):
        SymbolCALL.__init__(self, lineno, symbol, access)
        self.offset = offset

    @property
    def scope(self):
        return self.entry.scope

    @property
    def _mangled(self):
        return self.entry._mangled


