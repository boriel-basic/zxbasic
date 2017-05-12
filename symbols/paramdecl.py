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
from api.constants import SCOPE
from api.config import OPTIONS
import api.global_ as gl
from .type_ import SymbolBASICTYPE as BasicType
from .var import SymbolVAR


class SymbolPARAMDECL(SymbolVAR):
    ''' Defines a parameter declaration
    '''
    def __init__(self, varname, lineno, type_=None):
        SymbolVAR.__init__(self, varname, lineno, type_=type_, class_=CLASS.var)
        self.byref = OPTIONS.byref.value  # By default all params By value (false)
        self.offset = None  # Set by PARAMLIST, contains positive offset from top of the stack
        self.scope = SCOPE.parameter

    @property
    def size(self):
        if self.byref:
            return BasicType(gl.PTR_TYPE).size

        if self.type_ is None:
            return 0

        return self.type_.size + (self.type_.size % gl.PARAM_ALIGN)  # Make it even-sized (Float and Byte)
