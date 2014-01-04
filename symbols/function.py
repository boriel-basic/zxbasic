#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.constants import CLASS
from api.constants import KIND
from var import SymbolVAR
from paramlist import SymbolPARAMLIST
from block import SymbolBLOCK


class SymbolFUNCTION(SymbolVAR):
    ''' This class expands VAR top denote Function declarations
    '''
    def __init__(self, varname, lineno, offset=None, type_=None):
        SymbolVAR.__init__(self, varname, lineno, offset, class_=CLASS.function, type_=type_)
        self.callable = True
        self.params = SymbolPARAMLIST()
        self.body = SymbolBLOCK()
        self.__kind = KIND.unknown

    @classmethod
    def fromVAR(cls, entry, paramlist=None):
        ''' Returns this a copy of var as a VARFUNCTION
        '''
        result = cls(entry.name, entry.lineno, entry.offset)
        result.copy_attr(entry)  # This will destroy children
        result.class_ = CLASS.function

        if paramlist is None:
            paramlist = SymbolPARAMLIST()
        result.params = paramlist  # Regenerate them

        return result

    @property
    def params(self):
        if not self.children:
            return SymbolPARAMLIST()
        return self.children[0]

    @params.setter
    def params(self, value):
        assert isinstance(value, SymbolPARAMLIST)
        if self.children is None:
            self.children = []

        if self.children:
            self.children[0] = value
        else:
            self.children = [value]

    @property
    def body(self):
        if not self.children or len(self.children) < 2:
            self.body = SymbolBLOCK()

        return self.children[1]

    @body.setter
    def body(self, value):
        if value is None:
            value = SymbolBLOCK()
        assert isinstance(value, SymbolBLOCK)

        if self.children is None:
            self.children = []

        if not self.children:
            self.params = SymbolPARAMLIST()

        if len(self.children) < 2:
            self.children.append(value)
        else:
            self.children[1] = value


    def __repr__(self):
        return 'FUNC:{}'.format(self.name)
