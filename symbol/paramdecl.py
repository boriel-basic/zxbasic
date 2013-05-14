#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.constants import TYPE_SIZES
from api.constants import PTR_TYPE
from api.config import OPTIONS
from api.global_ import SYMBOL_TABLE
from symbol import Symbol


class SymbolPARAMDECL(Symbol):
    ''' Defines a parameter declaration
    '''
    def __init__(self, entry):
        Symbol.__init__(self, entry)
        self.__size = TYPE_SIZES[self.type_]
        self.__size = self.__size + (self.__size % 2)  # Make it even-sized (Float and Byte)
        self.byref = OPTIONS.byref.value  # By default all params By value (false)
        self.offset = None  # Set by PARAMLIST, contains positive offset from top of the stack

    @property
    def entry(self):
        return self.children[0]

    @property
    def type_(self):
        return self.entry.type_

    @property
    def size(self):
        if self.byref:
            return TYPE_SIZES[PTR_TYPE]

        return self.__size

    @classmethod
    def make_node(clss, id_, typedef, lineno):
        ''' A param decl is like a var decl, in the current scope (local
        variable). This will check that no ID with this name is already
        declared, an declares it.
        '''
        entry = SYMBOL_TABLE.make_paramdecl(id_, lineno, typedef.type_)
        if entry is None:
            return None
        entry.class_ = 'var'
        return clss(entry)
