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
from api.constants import TYPE_SIZES
from var import SymbolVAR


class SymbolVARARRAY(SymbolVAR):
    ''' This class expands VAR top denote Array Variables
    '''
    def __init__(self, varname, bounds, lineno, offset=None):
        SymbolVAR.__init__(self, varname, lineno, offset)
        self.appendChild(bounds)
        self.class_ = CLASS.array

    @property
    def bounds(self):
        return self.children[0]

    @property
    def count(self):
        ''' Total number of array cells
        '''
        return reduce(lambda x, y: x * y, (x.count for x in self.bounds))

    @property
    def size(self):
        return self.count * TYPE_SIZES[self.type_]

    @property
    def memsize(self):
        ''' Total array cell + indexes size
        '''
        return self.size + api.con

    @classmethod
    def fromVAR(clss, entry, bounds):
        ''' Returns this a copy of var as a VARARRAY
        '''
        result = clss(entry.name, bounds, entry.lineno, entry.offset)
        result.copy_attr(entry)  # This will destroy children
        result.appendChild(bounds)  # Regenerate them
        return result
