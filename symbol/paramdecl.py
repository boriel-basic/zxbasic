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
from obj import OPTIONS
from symbol import Symbol


class SymbolPARAMDECL(Symbol):
    ''' Defines a parameter declaration
    '''
    def __init__(self, symbol, _type):
        Symbol.__init__(self, symbol._mangled, 'PARAMDECL')
        self.entry = symbol
        self.__size = TYPE_SIZES[self._type]
        self.__size = self.__size + (self.__size % 2) # Make it even-sized (Float and Byte)
        self.byref = OPTIONS.byref.value    # By default all params By value (false)
        self.offset = None  # Set by PARAMLIST, contains positive offset from top of the stack

    @property
    def _type(self):
        return self.entry._type

    @property
    def size(self):
        if self.byref:
            return TYPE_SIZES['u16']

        return self.__size

