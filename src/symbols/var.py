#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from src.api import global_
from src.api.constants import CLASS, SCOPE
from src.symbols.id_ import SymbolID

# ----------------------------------------------------------------------
# Identifier Symbol object
# ----------------------------------------------------------------------


class SymbolVAR(SymbolID):
    """Defines an VAR (Variable) symbol.
    These class and their children classes are also stored in the symbol
    table as table entries to store variable data
    """

    _class: CLASS = CLASS.unknown

    def __init__(self, varname: str, lineno: int, offset=None, type_=None, class_: CLASS = CLASS.unknown):
        super().__init__(name=varname, lineno=lineno, filename=global_.FILENAME, type_=type_)
        assert class_ in {CLASS.unknown, CLASS.const, CLASS.var, CLASS.array}
        self.class_ = class_  # variable "class": var, label, function, etc.  TODO: should be CLASS.var
        self.offset = offset  # If local variable or parameter, +/- offset from top of the stack
        self.default_value = None  # If defined, variable will be initialized with this value (Arrays = List of Bytes)
        self.byref = False  # By default, it's a global var
        self.callable = None  # For functions, subs, arrays and strings this will be True

    @property
    def byref(self):
        return self.__byref

    @byref.setter
    def byref(self, value: bool):
        assert isinstance(value, bool)
        self.__byref = value

    def __str__(self):
        return self.name

    def __repr__(self):
        return "ID:%s" % str(self)

    @property
    def t(self):
        # HINT: Parameters and local variables must have it's .t member as '$name'
        if self.class_ == CLASS.const:
            return str(self.value)

        if self.scope == SCOPE.global_:
            if self.class_ == CLASS.array:
                return self.data_label
            else:
                return self.mangled

        if self.type_ is None or not self.type_.is_dynamic:
            return self._t

        return "$" + self._t  # Local string variables (and parameters) use '$' (see backend)

    @property
    def value(self):
        """An alias of default value, only available is class_ is CONST"""
        assert self.class_ == CLASS.const
        if isinstance(self.default_value, SymbolVAR):
            return self.default_value.value

        return self.default_value

    @value.setter
    def value(self, val):
        assert self.class_ == CLASS.const
        self.default_value = val
