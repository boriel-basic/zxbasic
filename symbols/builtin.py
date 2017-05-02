#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .symbol_ import Symbol
from .number import SymbolNUMBER
from .type_ import SymbolTYPE

from api.check import is_number
from api.check import is_string


class SymbolBUILTIN(Symbol):
    ''' Defines an BUILTIN function e.g. INKEY$(), RND() or LEN
    '''
    def __init__(self, lineno, fname, type_=None, *operands):
        assert isinstance(lineno, int)
        assert type_ is None or isinstance(type_, SymbolTYPE)
        Symbol.__init__(self, *operands)
        self.lineno = lineno
        self.fname = fname
        self.type_ = type_

    @property
    def type_(self):
        if self._type is not None:
            return self._type
        return self.operand.type_

    @type_.setter
    def type_(self, value):
        assert value is None or isinstance(value, SymbolTYPE)
        self._type = value

    @property
    def operand(self):
        return self.children[0] if self.children else None

    @operand.setter
    def operand(self, value):
        assert isinstance(value, Symbol)
        self.children[0] = value

    @property
    def operands(self):
        return self.children

    @operands.setter
    def operands(self, value):
        for x in value:
            assert isinstance(x, Symbol)
        self.children = [x for x in value]

    @property
    def size(self):
        ''' sizeof(type)
        '''
        if self.type_ is None:
            return 0
        return self.type_.size

    @classmethod
    def make_node(cls, lineno, fname, func=None, type_=None, *operands):
        ''' Creates a node for a unary operation. E.g. -x or LEN(a$)

        Parameters:
            -func: function used on constant folding when possible
            -type_: the resulting type (by default, the same as the argument).
                For example, for LEN (str$), result type is 'u16'
                and arg type is 'string'
        '''
        if func is not None and len(operands) == 1:  # Try constant-folding
            if is_number(operands[0]) or is_string(operands[0]):  # e.g. ABS(-5)
                return SymbolNUMBER(func(operands[0].value), type_=type_, lineno=lineno)

        return cls(lineno, fname, type_, *operands)
