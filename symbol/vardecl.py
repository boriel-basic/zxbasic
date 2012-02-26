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



class VarDecl(Symbol):
    ''' Defines a Variable declaration
    '''
    def __init__(self, symbol):
        Symbol.__init__(self, symbol._mangled, 'VARDECL')
        self.var = symbol

    @property
    def default_value(self):
        return self.var.default_value

    @property
    def _type(self):
        return self.var._type

    @property
    def size(delf):
        return self.var.size

