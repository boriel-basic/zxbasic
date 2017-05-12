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
from .string_ import SymbolSTRING
from .typecast import SymbolTYPECAST
from .type_ import SymbolTYPE
from .type_ import Type as TYPE

from api.check import is_number
from api.check import is_string


class SymbolUNARY(Symbol):
    ''' Defines an UNARY EXPRESSION e.g. (a + b)
        Only the operator (e.g. 'PLUS') is stored.
    '''
    def __init__(self, oper, operand, lineno, type_=None):
        Symbol.__init__(self, operand)
        self.lineno = lineno
        self.operator = oper
        self._type = type_

    @property
    def type_(self):
        if self._type is not None:
            return self._type
        return self.operand.type_

    @property
    def size(self):
        ''' sizeof(type)
        '''
        if self.type_ is None:
            return 0
        return self.type_.size

    @property
    def operand(self):
        return self.children[0]

    @operand.setter
    def operand(self, value):
        self.children[0] = value

    def __str__(self):
        return '%s(%s)' % (self.operator, self.operand)

    def __repr__(self):
        return '(%s: %s)' % (self.operator, self.operand)

    @classmethod
    def make_node(clss, lineno, operator, operand, func=None, type_=None):
        ''' Creates a node for a unary operation. E.g. -x or LEN(a$)

        Parameters:
            -func: lambda function used on constant folding when possible
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
            type_ = TYPE.ubyte

        return clss(operator, operand, lineno, type_)
