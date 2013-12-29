#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol_ import Symbol
from number import SymbolNUMBER
from string_ import SymbolSTRING
from typecast import SymbolTYPECAST
from type_ import SymbolTYPE
from type_ import SymbolBASICTYPE

from api.check import is_number
from api.check import is_string
from api.constants import TYPE_SIZES
from api.constants import TYPE


class SymbolBUILTIN(Symbol):
    ''' Defines an BUILTIN function e.g. INKEY$(), RND() or LEN
    '''
    def __init__(self, fname, lineno, type_, *args):
        Symbol.__init__(self, operand)
        self.lineno = lineno
        self.fname = fname
        self.type_ = type_

    @property
    def size(self):
        ''' sizeof(type)
        '''
        if self.type_ is None:
            return 0
        return self.type_.size

    @classmethod
    def make_node(cls, lineno, operator, operand, func=None, type_=None):
        ''' Creates a node for a unary operation. E.g. -x or LEN(a$)

        Parameters:
            -func: function used on constant folding when possible
            -type_: the resulting type (by default, the same as the argument).
                For example, for LEN (str$), result type is 'u16'
                and arg type is 'string'
        '''
        assert type_ is None or isinstance(type_, SymbolTYPE)

        if func is not None:  # Try constant-folding
            if is_number(operand):  # e.g. ABS(-5)
                return SymbolNUMBER(func(operand.value), lineno=lineno)
            elif is_string(operand):  # e.g. LEN("a")
                return SymbolSTRING(func(operand.text), lineno=lineno)

        if type_ is None:
            type_ = operand.type_

        if operator == 'MINUS':
            if not type_.is_signed:
                type_ = type_.to_signed()
                operand = SymbolTYPECAST.make_node(type_, operand, lineno)
        elif operator == 'NOT':
            type_ = SymbolBASICTYPE(None, TYPE.ubyte)

        return cls(operator, operand, lineno, type_)
