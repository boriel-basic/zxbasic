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

from api.check import is_number
from api.check import is_string
from api.constants import TYPE_SIZES
from api.constants import TYPE


class SymbolUNARY(Symbol):
    ''' Defines an UNARY EXPRESSION e.g. (a + b)
        Only the operator (e.g. 'PLUS') is stored.
    '''
    def __init__(self, oper, operand, lineno):
        Symbol.__init__(self, operand)
        self.lineno = lineno
        self.operator = oper

    @property
    def type_(self):
        return self.operand.type_

    @property
    def size(self):
        ''' sizeof(type)
        '''
        return TYPE_SIZES[self.type_]

    @property
    def operand(self):
        return self.children[0]

    @operand.setter
    def operand(self, value):
        self.children[0] = value

    def __str__(self):
        return '%s%s' % (self.operator, self.operand)

    def __repr__(self):
        return '(%s: %s)' % (self.operator, self.operand)

    @classmethod
    def make_node(clss, lineno, operator, operand, func=None, type_=None):
        ''' Creates a node for a unary operation. E.g. -x or LEN(a$)

        Parameters:
            -func: lambda function used on consant folding when possible
            -type_: the resulting type (by default, the same as the argument).
                For example, for LEN (str$), result type is 'u16'
                and arg type is 'string'
        '''
        if func is not None:  # Try constant-folding
            if is_number(operand):  # e.g. ABS(-5)
                return SymbolNUMBER(func(operand.value), lineno=lineno)
            elif is_string(operand):  # e.g. LEN("a")
                return SymbolSTRING(func(operand.text), lineno=lineno)

        if type_ is None:
            type_ = operand.type_

        if operator == 'MINUS':
            if not TYPE.is_signed(type_):
                type_ = TYPE.to_signed(type_)
                operand = SymbolTYPECAST.make_node(type_, operand, lineno)
        elif operator == 'NOT':
            type_ = TYPE.ubyte

        return clss(operator, operand, lineno)
