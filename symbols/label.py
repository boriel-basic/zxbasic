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
from .var import SymbolVAR
from .symbol_ import Symbol


class SymbolLABEL(SymbolVAR):
    prefix = '__LABEL__'

    def __init__(self, name, lineno):
        SymbolVAR.__init__(self, name, lineno)
        self.class_ = CLASS.label
        self._scope_owner = []  # list of nested functions containing this label (scope)

    @property
    def t(self):
        """ t property is constant for labels
        """
        return self.prefix + self.name

    @property
    def accessed(self):
        return self._accessed

    @accessed.setter
    def accessed(self, value):
        self._accessed = bool(value)
        if self._accessed:
            for entry in self.scope_owner:
                entry.accessed = True

    @property
    def scope_owner(self):
        return list(self._scope_owner)

    @scope_owner.setter
    def scope_owner(self, entries):
        assert all(isinstance(x, Symbol) for x in entries)
        self._scope_owner = list(entries)
        self.accessed = self._accessed  # if true, refresh scope_owners
