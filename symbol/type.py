#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol import Symbol
from constants import TYPE_NAMES
from constants import TYPE_SIZES


class Type(Symbol):
    ''' Defines a type definition.
    '''
    def __init__(self, _type, lineno, implicit = False):
        ''' Implicit = True if this type has been
        "inferred" by default, or by the expression surrounding
        the ID.
        '''
        Symbol.__init__(self, _type, 'TYPE')
        self._type = TYPE_NAMES[_type.lower()]
        self.size = TYPE_SIZES[self._type]
        self.lineno = lineno
        self.implicit = implicit

