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
from var import SymbolVAR
from paralist import SymbolPARAMLIST


class SymbolFUNCTION(SymbolVAR):
    ''' This class expands VAR top denote Function delaations
    '''
    def __init__(self, varname, lineno, offset=None):
        SymbolVAR.__init__(self, varname, lineno, offset)
        self.class_ = CLASS.function

    @classmethod
    def fromVAR(clss, entry, paramlist=None):
        ''' Returns this a copy of var as a VARFUNCTION
        '''
        result = clss(entry.name, entry.lineno, entry.offset)
        result.copy_attr(entry)  # This will destroy children
        if paramlist is None:
            paramlist = SymbolPARAMLIST()
        result.appendChild(paramlist)  # Regenerate them
        return result

    @property
    def params(self):
        return self.children[0]

    @params.setter
    def params(self, value):
        if self.children:
            self.children[0] = value
        else:
            self.children = [value]

