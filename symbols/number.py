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

from api.constants import TYPE
from symbol_ import Symbol
from type_ import SymbolTYPE
from type_ import SymbolBASICTYPE
from type_ import SymbolTYPEREF


class SymbolNUMBER(Symbol):
    ''' Defines an NUMBER symbol.
    '''
    def __init__(self, value, type_=None, lineno=None):
        assert lineno is not None
        assert type_ is None or isinstance(type_, SymbolTYPE)
        assert isinstance(value, numbers.Number)

        Symbol.__init__(self)

        if int(value) == value:
            value = int(value)
        else:
            value = float(value)

        self.value = value

        if type_ is not None:
            self.type_ = type_

        elif isinstance(value, float):
            if -32768.0 < value < 32767:
                self.type_ = SymbolBASICTYPE(None, TYPE.fixed)
            else:
                self.type_ = SymbolBASICTYPE(None, TYPE.float_)

        elif isinstance(value, int):
            if 0 <= value < 256:
                self.type_ = SymbolBASICTYPE(None, TYPE.ubyte)
            elif -128 <= value < 128:
                self.type_ = SymbolBASICTYPE(None, TYPE.byte_)
            elif 0 <= value < 65536:
                self.type_ = SymbolBASICTYPE(None, TYPE.uinteger)
            elif -32768 <= value < 32768:
                self.type_ = SymbolBASICTYPE(None, TYPE.integer)
            elif value < 0:
                self.type_ = SymbolBASICTYPE(None, TYPE.long_)
            else:
                self.type_ = SymbolBASICTYPE(None, TYPE.ulong)

        self.type_ = SymbolTYPEREF(self.type_, lineno)
        self.lineno = lineno

    def __str__(self):
        return str(self.value) + 'pi'

    def __repr__(self):
        return "%s:%s" % (self.type_, str(self))

    def __cmp__(self, other):
        if isinstance(other, numbers.Number):
            return self.value - other

        assert isinstance(other, SymbolNUMBER)
        return self.value - other.value
