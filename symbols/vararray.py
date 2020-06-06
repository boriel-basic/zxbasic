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
from api.constants import SCOPE
from .var import SymbolVAR
from .boundlist import SymbolBOUNDLIST


class SymbolVARARRAY(SymbolVAR):
    """ This class expands VAR top denote Array Variables
    """
    lbound_used = False  # True if LBound has been used on this array
    ubound_used = False  # True if UBound has been used on this array

    def __init__(self, varname, bounds, lineno, offset=None, type_=None):
        super(SymbolVARARRAY, self).__init__(varname, lineno, offset=offset, type_=type_, class_=CLASS.array)
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
        """ Total number of array cells
        """
        return functools.reduce(lambda x, y: x * y, (x.count for x in self.bounds))

    @property
    def size(self):
        return self.count * self.type_.size if self.scope != SCOPE.parameter else TYPE.size(gl.PTR_TYPE)

    @property
    def memsize(self):
        """ Total array cell + indexes size
        """
        return (2 + (2 if self.lbound_used or self.ubound_used else 0)) * TYPE.size(gl.PTR_TYPE)

    @property
    def data_label(self):
        return '{}.{}'.format(self.mangled, gl.ARRAY_DATA_PREFIX)

    @property
    def data_ptr_label(self):
        return '{}.{}'.format(self.data_label, '__PTR__')
