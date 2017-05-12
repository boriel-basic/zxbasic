#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------


from .symbol_ import Symbol
from .typecast import SymbolTYPECAST
from .var import SymbolVAR
from api.config import OPTIONS
from api.constants import SCOPE


class SymbolARGUMENT(Symbol):
    """ Defines an argument in a function call
    """

    def __init__(self, value, lineno, byref=None):
        """ Initializes the argument data. Byref must be set
        to True if this Argument is passed by reference.
        """
        super(SymbolARGUMENT, self).__init__(value)
        self.lineno = lineno
        self.byref = byref if byref is not None else OPTIONS.byref.value

    @property
    def t(self):
        if self.byref or not self.type_.is_dynamic:
            return self.value.t

        if self.value.token in ('VAR', 'PARAMDECL'):
            if self.value.scope == SCOPE.global_:
                return self.value.t
            else:
                return self.value.t[1:]  # Removed '$' prefix

        return self.value.t

    @property
    def value(self):
        return self.children[0]

    @value.setter
    def value(self, val):
        self.children[0] = val

    @property
    def type_(self):
        return self.value.type_

    @property
    def class_(self):
        return self.value.class_

    @property
    def byref(self):
        return self._byref

    @byref.setter
    def byref(self, value):
        if value:
            assert isinstance(self.value, SymbolVAR)
        self._byref = value

    @property
    def mangled(self):
        return self.value.mangled

    @property
    def size(self):
        return self.type_.size

    def __hash__(self):
        return id(self)

    def __eq__(self, other):
        assert isinstance(other, Symbol)
        if isinstance(other, SymbolARGUMENT):
            return self.value == other.value
        return self.value == other

    def typecast(self, type_):
        """ Test type casting to the argument expression.
        On sucess changes the node value to the new typecast, and returns
        True. On failure, returns False, and the node value is set to None.
        """
        self.value = SymbolTYPECAST.make_node(type_, self.value, self.lineno)
        return self.value is not None
