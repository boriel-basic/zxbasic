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


class SymbolARRAYDECL(Symbol):
    ''' Defines an Array declaration
    '''
    def __init__(self, entry):
        Symbol.__init__(self, entry.mangled_)
        self.entry = entry # Symbol table entry

    @property
    def type_(self):
        return self.entry.type_
        
    @property
    def memsize(self):
        ''' Total array cell + indexes size
        '''
        return self.entry.total_size

    @property
    def bounds(self):
        return self.entry.bounds

    def __str__(self):
        return "%s(%s)" % (self.entry.id, self.bounds)

    def __repr__(self):
        return str(self)
        