#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import functools

import api.global_ as gl
from api.constants import TYPE
from api.constants import CLASS
from .var import SymbolVAR
from .boundlist import SymbolBOUNDLIST


class SymbolVARARRAY(SymbolVAR):
    ''' This class expands VAR top denote Array Variables
    '''
    def __init__(self, varname, bounds, lineno, offset=None, type_=None):
        SymbolVAR.__init__(self, varname, lineno, offset=offset, type_=type_, class_=CLASS.array)
        self.bounds = bounds

    @property
    def bounds(self):
        return self.children[0]

    @bounds.setter
    def bounds(self, value):
        assert isinstance(value, SymbolBOUNDLIST)
        self.children = [value]

    @property
    def count(self):
        ''' Total number of array cells
        '''
        return functools.reduce(lambda x, y: x * y, (x.count for x in self.bounds))

    @property
    def size(self):
        return self.count * self.type_.size

    @property
    def memsize(self):
        ''' Total array cell + indexes size
        '''
        return self.size + 1 + TYPE.size(gl.BOUND_TYPE) * len(self.bounds)
