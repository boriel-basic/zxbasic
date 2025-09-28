# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api import check
from src.symbols.number import SymbolNUMBER
from src.symbols.string_ import SymbolSTRING
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import SymbolTYPE
from src.symbols.type_ import Type as TYPE
from src.symbols.typecast import SymbolTYPECAST


class SymbolUNARY(Symbol):
    """Defines a UNARY EXPRESSION e.g. (a + b)
    Only the operator (e.g. 'PLUS') is stored.
    """

    def __init__(self, oper, operand, lineno, type_=None):
        super().__init__(operand)
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
        """sizeof(type)"""
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
        return "%s(%s)" % (self.operator, self.operand)

    def __repr__(self):
        return "(%s: %s)" % (self.operator, self.operand)

    @classmethod
    def make_node(cls, lineno, operator, operand, func=None, type_=None):
        """Creates a node for a unary operation. E.g. -x or LEN(a$)

        Parameters:
            -func: lambda function used on constant folding when possible
            -type_: the resulting type (by default, the same as the argument).
                For example, for LEN (str$), result type is 'u16'
                and arg type is 'string'
        """
        assert type_ is None or isinstance(type_, SymbolTYPE)

        if func is not None:  # Try constant-folding
            if check.is_number(operand):  # e.g. ABS(-5)
                return SymbolNUMBER(func(operand.value), lineno=lineno)
            if check.is_string(operand):  # e.g. LEN("a")
                return SymbolSTRING(func(operand.text), lineno=lineno)

        if type_ is None:
            type_ = operand.type_

        if operator == "MINUS":
            if not type_.is_signed:
                type_ = type_.to_signed()
                operand = SymbolTYPECAST.make_node(type_, operand, lineno)
        elif operator == "NOT":
            type_ = TYPE.boolean

        return cls(operator, operand, lineno, type_)
