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
from .const import SymbolCONST
from .number import SymbolNUMBER
from .string_ import SymbolSTRING
from .typecast import SymbolTYPECAST
from .type_ import Type as TYPE

from api.check import common_type
from api.check import is_const
from api.check import is_number
from api.check import is_static
from api.check import is_numeric
from api.check import is_string
from api.errmsg import syntax_error


class SymbolBINARY(Symbol):
    ''' Defines a BINARY EXPRESSION e.g. (a + b)
        Only the operator (e.g. 'PLUS') is stored.
    '''
    def __init__(self, operator, left, right, lineno, type_=None, func=None):
        Symbol.__init__(self, left, right)
        self.lineno = lineno
        self.operator = operator
        self.type_ = type_ if type_ is not None else common_type(left, right)
        self.func = func  # Will be used for constant folding at later stages if not None

    @property
    def left(self):
        return self.children[0]

    @left.setter
    def left(self, value):
        assert isinstance(value, Symbol)
        self.children[0] = value

    @property
    def right(self):
        return self.children[1]

    @right.setter
    def right(self, value):
        assert isinstance(value, Symbol)
        self.children[1] = value

    def __str__(self):
        return '%s %s %s' % (self.left, self.operator, self.right)

    def __repr__(self):
        return '(%s: %s %s)' % (self.operator, self.left, self.right)

    @property
    def size(self):
        return self.type_.size

    @classmethod
    def make_node(cls, operator, left, right, lineno, func=None,
                  type_=None):
        ''' Creates a binary node for a binary operation,
            e.g. A + 6 => '+' (A, 6) in prefix notation.

            Parameters:
            -operator: the binary operation token. e.g. 'PLUS' for A + 6
            -left: left operand
            -right: right operand
            -func: is a lambda function used when constant folding is applied
            -type_: resulting type (to enforce it).

            If no type_ is specified the resulting one will be guessed.
        '''
        if left is None or right is None:
            return None
        
        a, b = left, right  # short form names
        # Check for constant non-numeric operations
        c_type = common_type(a, b)  # Resulting operation type or None
        if c_type:  # there must be a common type for a and b
            if is_numeric(a, b) and (is_const(a) or is_number(a)) and\
                    (is_const(b) or is_number(b)):
                if func is not None:
                    a = SymbolTYPECAST.make_node(c_type, a, lineno)  # ensure type
                    b = SymbolTYPECAST.make_node(c_type, b, lineno)  # ensure type
                    return SymbolNUMBER(func(a.value, b.value), type_=type_,
                                lineno=lineno)

            if is_static(a, b):
                a = SymbolTYPECAST.make_node(c_type, a, lineno)  # ensure type
                b = SymbolTYPECAST.make_node(c_type, b, lineno)  # ensure type
                return SymbolCONST(cls(operator, a, b, lineno, type_=type_, func=func), lineno=lineno)

        if operator in ('BNOT', 'BAND', 'BOR', 'BXOR', 'NOT', 'AND', 'OR',
                        'XOR', 'MINUS', 'MULT', 'DIV', 'SHL', 'SHR') and \
                not is_numeric(a, b):
            syntax_error(lineno, 'Operator %s cannot be used with STRINGS' % operator)
            return None

        if is_string(a, b) and func is not None:  # Are they STRING Constants?
            if operator == 'PLUS':
                return SymbolSTRING(func(a.value, b.value), lineno)

            return SymbolNUMBER(int(func(a.text, b.text)), type_=TYPE.ubyte,
                                lineno=lineno)  # Convert to u8 (boolean)

        if operator in ('BNOT', 'BAND', 'BOR', 'BXOR'):
            if TYPE.is_decimal(c_type):
                c_type = TYPE.long_

        if operator not in ('SHR', 'SHL'):
            a = SymbolTYPECAST.make_node(c_type, a, lineno)
            b = SymbolTYPECAST.make_node(c_type, b, lineno)

        if a is None or b is None:
            return None

        if type_ is None:
            if operator in ('LT', 'GT', 'EQ', 'LE', 'GE', 'NE', 'AND', 'OR',
                            'XOR', 'NOT'):
                type_ = TYPE.ubyte  # Boolean type
            else:
                type_ = c_type

        return cls(operator, a, b, type_=type_, lineno=lineno)
