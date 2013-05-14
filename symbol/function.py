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


class SymbolFUNCTION(SymbolVAR):
    ''' This class expands VAR top denote Function delaations
    '''
    def __init__(self, varname, lineno, offset=None):
        SymbolVAR.__init__(self, varname, lineno, offset)
        self.class_ = CLASS.function

    @classmethod
    def fromVAR(clss, entry, bounds):
        ''' Returns this a copy of var as a VARARRAY
        '''
        result = clss(entry.name, bounds, entry.lineno, entry.offset)
        result.copy_attr(entry)  # This will destroy children
        result.appendChild(bounds)  # Regenerate them
        return result
