#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from constants import TYPE_SIZES
from symbol import Symbol


class SymbolFUNCDECL(Symbol):
    ''' Defines a Function declaration
    '''
    def __init__(self, symbol):
        Symbol.__init__(self, symbol._mangled, 'FUNCDECL')
        self.fname = symbol.id
        self._mangled = symbol._mangled
        self.entry = symbol # Symbol table entry

    def __get_locals_size(self):
        return self.entry.locals_size

    def __set_locals_size(self, value):
        self.entry.locals_size = value

    locals_size = property(__get_locals_size, __set_locals_size)

    def __get_type(self):
        return self.entry._type

    def __set_type(self, value):
        self.entry._type = value

    _type = property(__get_type, __set_type)

    @property
    def size(self):
        return TYPE_SIZES[self._type]


