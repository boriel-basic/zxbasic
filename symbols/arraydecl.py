#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.constants import TYPE
from .symbol_ import Symbol


class SymbolARRAYDECL(Symbol):
    ''' Defines an Array declaration
    '''
    def __init__(self, entry):
        Symbol.__init__(self, entry)

    @property
    def name(self):
        return self.entry.name

    @property
    def mangled(self):
        return self.entry.mangled

    @property
    def entry(self):
        return self.children[0]

    @property
    def type_(self):
        return self.entry.type_

    @property
    def size(self):
        ''' Total memory size of array cells
        '''
        return self.type_.size * self.count

    @property
    def count(self):
        ''' Total number of array cells
        '''
        return self.entry.count

    @property
    def memsize(self):
        ''' Total array cell + indexes size
        '''
        return self.entry.memsize

    @property
    def bounds(self):
        return self.entry.bounds

    def __str__(self):
        return "%s(%s)" % (self.entry.name, self.bounds)

    def __repr__(self):
        return str(self)
