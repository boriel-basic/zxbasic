#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api import global_
from api.constants import TYPE_SIZES
from symbol_ import Symbol


class SymbolFUNCDECL(Symbol):
    ''' Defines a Function declaration
    '''
    def __init__(self, entry):
        Symbol.__init__(self)
        self.entry = entry  # Symbol table entry

    @property
    def name(self):
        return self.entry.name

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

    @classmethod
    def make_node(clss, func_name, lineno):
        ''' This will return a node with the symbol as a function.
        '''
        entry = global_.SYMBOL_TABLE.make_func(func_name, lineno)
        if entry is None:
            return None

        entry.declared = True
        return clss(entry)
