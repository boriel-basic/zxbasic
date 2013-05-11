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
from symbol import Symbol


class SymbolTYPE(Symbol):
    ''' Defines a type declaration of a variable.
    '''
    def __init__(self, type_, lineno, implicit = False):
        ''' Implicit = True if this type has been
        "inferred" by default, or by the expression surrounding
        the ID.
        '''
        Symbol.__init__(self, type_)
        self.type_ = type_
        self.size = TYPE_SIZES[self.type_]
        self.lineno = lineno
        self.implicit = implicit


