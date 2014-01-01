#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import numbers

from api.constants import CLASS
from symbol_ import Symbol
from type_ import SymbolTYPE
from type_ import SymbolTYPEREF
from type_ import Type as TYPE


class SymbolNUMBER(Symbol):
    ''' Defines an NUMBER symbol.
    '''
    def __init__(self, value, lineno, type_=None):
        assert lineno is not None
        assert type_ is None or isinstance(type_, SymbolTYPE)
        assert isinstance(value, numbers.Number)

        Symbol.__init__(self)
        self.class_ = CLASS.const

        if int(value) == value:
            value = int(value)
        else:
            value = float(value)

        self.value = value

        if type_ is not None:
            self.type_ = type_

        elif isinstance(value, float):
            if -32768.0 < value < 32767:
                self.type_ = TYPE.fixed
            else:
                self.type_ = TYPE.float_

        elif isinstance(value, int):
            if 0 <= value < 256:
                self.type_ = TYPE.ubyte
            elif -128 <= value < 128:
                self.type_ = TYPE.byte_
            elif 0 <= value < 65536:
                self.type_ = TYPE.uinteger
            elif -32768 <= value < 32768:
                self.type_ = TYPE.integer
            elif value < 0:
                self.type_ = TYPE.long_
            else:
                self.type_ = TYPE.ulong

        self.type_ = SymbolTYPEREF(self.type_, lineno)
        self.lineno = lineno

    def __str__(self):
        return str(self.value)

    def __repr__(self):
        return "%s:%s" % (self.type_, str(self))

    @property
    def t(self):
        return str(self)

    def __cmp__(self, other):
        if isinstance(other, numbers.Number):
            return self.value - other

        assert isinstance(other, SymbolNUMBER)
        return self.value - other.value
