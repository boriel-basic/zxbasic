#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------
from typing import Optional

import src.api.global_ as gl

from src.api.constants import CLASS
from src.api.constants import SCOPE
from src.api.config import OPTIONS
from src.symbols.type_ import SymbolBASICTYPE as BasicType
from src.symbols.var import SymbolVAR
from src.symbols.symbol_ import Symbol


class SymbolPARAMDECL(SymbolVAR):
    """Defines a parameter declaration"""

    def __init__(self, varname: str, lineno: int, type_=None, default_value: Optional[Symbol] = None):
        super().__init__(varname, lineno, type_=type_, class_=CLASS.var)
        self.byref = OPTIONS.default_byref  # By default all params By value (false)
        self.offset = None  # Set by PARAMLIST, contains positive offset from top of the stack
        self.scope = SCOPE.parameter
        self.default_value = default_value

    @property
    def size(self):
        if self.byref:
            return BasicType(gl.PTR_TYPE).size

        if self.type_ is None:
            return 0

        return self.type_.size + (self.type_.size % gl.PARAM_ALIGN)  # Make it even-sized (Float and Byte)
