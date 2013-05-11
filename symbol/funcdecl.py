#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.constants import TYPE_SIZES
from symbol import Symbol


class SymbolFUNCDECL(Symbol):
    ''' Defines a Function declaration
    '''
    def __init__(self, entry):
        Symbol.__init__(self)
        self.entry = symbol # Symbol table entry
        
    @property
    def name(self):
        return self.entry.id_

    @property
    def locals_size(self):
        return self.entry.locals_size

    @locals_size.setter
    def locals_size(self, value):
        self.entry.locals_size = value

    @property
    def type_(self):
        return self.entry.type_

    @type_.setter
    def type_(self, value):
        self.entry.type_ = value

    @property
    def size(self):
        return TYPE_SIZES[self._type]

    @property
    def mangled_(self):
        return self.entry.mangled_

