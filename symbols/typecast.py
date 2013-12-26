#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol_ import Symbol
from type_ import SymbolTYPE
from number import SymbolNUMBER
from api.constants import TYPE_SIZES
from api.constants import TYPE
from api.constants import CLASS
from api.errmsg import syntax_error
from api import errmsg
from api.check import is_const
from api.check import is_number


class SymbolTYPECAST(Symbol):
    ''' Defines a typecast operation.
    '''
    def __init__(self, new_type, operand, lineno):
        Symbol.__init__(self, operand)
        self.lineno = lineno
        self.type_ = new_type

    ## The converted (typecast) node
    @property
    def operand(self):
        return self.children[0]

    @operand.setter
    def operand(self, operand_):
        self.children[0] = operand_

    @classmethod
    def make_node(cls, new_type, node, lineno):
        ''' Creates a node containing the type cast of
        the given one. If new_type == node.type, then
        nothing is done, and the same node is
        returned.

        Returns None on failure (and calls syntax_error)
        '''
        assert isinstance(new_type, SymbolTYPE)

        # None (null) means the given AST node is empty (usually an error)
        if node is None:
            return None  # Do nothing. Return as is

        # The source and dest types are the same
        if new_type == node.type_:
            return node  # Do nothing. Return as is

        # Typecasting, at the moment, only for number
        if node.type_ == TYPE.string:
            syntax_error(lineno, 'Cannot convert string to a value. '
                                 'Use VAL() function')
            return None

        # Converting from string to number is done by STR
        if new_type == TYPE.string:
            syntax_error(lineno, 'Cannot convert value to string. '
                                 'Use STR() function')
            return None

        # If the given operand is a constant, perform a static typecast
        if is_const(node.symbol):
            node = node.expr

        if not is_number(node):
            return cls(new_type, node, lineno)

        # It's a number. So let's convert it directly
        if node.token != 'NUMBER':
            if node.class_ == CLASS.const:
                node = SymbolNUMBER(node.value, node.type_, node.lineno)

        if new_type not in TYPE.integral:  # not an integer
            node.value = float(node.value)
        else:  # It's an integer
            new_val = (int(node.value) &
                      ((1 << (8 * TYPE_SIZES[new_type])) - 1))  # Mask it

            if node.value >= 0 and node.value != new_val:
                errmsg.warning_conversion_lose_digits(node.symbol.lineno)
                node.value = new_val
            elif node.value < 0 and (1 << (TYPE_SIZES[new_type] * 8)) + \
                    node.value != new_val:
                errmsg.warning_conversion_lose_digits(node.symbol.lineno)
                node.value = new_val - (1 << (TYPE_SIZES[new_type] * 8))

        node.type_ = new_type
        return node
