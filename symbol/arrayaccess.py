#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import gl
from symbol import Symbol
from call import Call
from error import Error


class ArrayAccess(Call):
    ''' Defines an array access. It's pretty much like a function call
    (e.g. A(1, 2) could be an array access or a function call, depending on
    context). So we derive this class from SymbolCall

    Initializing this with SymbolArrayAccess(symbol, ARRAYLOAD) will
    make the returned expression to be loaded into the stack (by default
    it only returns the pointer address to the element)
    '''
    def __init__(self, lineno, variable, arglist, access = 'ARRAYACCESS', offset = None):
        Call.__init__(self, lineno, variable, arglist, access)
        self.offset = offset
        self.index = self.params # Array indexes (expressions)

    @property
    def scope(self):
        return self.entry.scope

    @property
    def _mangled(self):
        return self.entry._mangled
    
    @classmethod
    def create(cls, lineno, variable, arglist, access, offset):
        for i in arglist:
            if not isinstance(i, Symbol):
                raise Error('Not a Symbol element "%s"' % str(i))

        entry = gl.SYMBOL_TABLE.make_callable(variable, lineno)
        result = cls(lineno, entry, arglist, access, offset)

        return result

    @property
    def child(self):
        return list(self.index)

