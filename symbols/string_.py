#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import six

from api.constants import CLASS
from .symbol_ import Symbol
from .type_ import Type


class SymbolSTRING(Symbol):
    ''' Defines a string constant.
    '''
    def __init__(self, value, lineno):
        assert isinstance(value, str) or isinstance(value, SymbolSTRING)
        Symbol.__init__(self)
        self.value = value
        self.type_ = Type.string
        self.lineno = lineno
        self.class_ = CLASS.const
        self.t = value

    @property
    def t(self):
        return self._t

    @t.setter
    def t(self, value):
        assert isinstance(value, str)
        self._t = value

    def __str__(self):
        return self.value

    def __repr__(self):
        return '"%s"' % str(self)

    def __eq__(self, other):
        if isinstance(other, six.string_types):
            return self.value == other

        assert isinstance(other, SymbolSTRING)
        return self.value == other.value

    def __gt__(self, other):
        if type(other) in six.string_types:
            return self.value > other

        assert isinstance(other, SymbolSTRING)
        return self.value > other.value

    def __lt__(self, other):
        if type(other) in six.string_types:
            return self.value < other

        assert isinstance(other, SymbolSTRING)
        return self.value < other.value

    def __hash__(self):
        return id(self)

    def __ne__(self, other):
        return not self.__eq__(other)

    def __ge__(self, other):
        return not self.__lt__(other)

    def __le__(self, other):
        return not self.__gt__(other)



