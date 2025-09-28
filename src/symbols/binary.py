# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api import check, errmsg
from src.symbols.constexpr import SymbolCONSTEXPR
from src.symbols.number import SymbolNUMBER
from src.symbols.string_ import SymbolSTRING
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import Type as TYPE
from src.symbols.typecast import SymbolTYPECAST


class SymbolBINARY(Symbol):
    """Defines a BINARY EXPRESSION e.g. (a + b)
    Only the operator (e.g. 'PLUS') is stored.
    """

    def __init__(self, operator: str, left: Symbol, right: Symbol, lineno: int, type_=None, func=None):
        super().__init__(left, right)
        self.lineno = lineno
        self.operator = operator
        self.type_ = type_ if type_ is not None else check.common_type(left, right)
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
        return "%s %s %s" % (self.left, self.operator, self.right)

    def __repr__(self):
        return "(%s: %s %s)" % (self.operator, self.left, self.right)

    @property
    def size(self):
        return self.type_.size

    @classmethod
    def make_node(cls, operator, left, right, lineno, func=None, type_=None):
        """Creates a binary node for a binary operation,
        e.g. A + 6 => '+' (A, 6) in prefix notation.

        Parameters:
        -operator: the binary operation token. e.g. 'PLUS' for A + 6
        -left: left operand
        -right: right operand
        -func: is a lambda function used when constant folding is applied
        -type_: resulting type (to enforce it).

        If no type_ is specified the resulting one will be guessed.
        """
        if left is None or right is None:
            return None

        a, b = left, right  # short form names
        if operator in {
            "BAND",
            "BOR",
            "BXOR",
            "AND",
            "OR",
            "XOR",
            "MINUS",
            "MULT",
            "DIV",
            "SHL",
            "SHR",
        } and not check.is_numeric(a, b):
            errmsg.error(lineno, f"Operator {operator} cannot be used with strings")
            return None

        if operator not in {"AND", "OR", "XOR"}:
            # Non-boolean operators use always numeric operands.
            # We ensure operands are correctly converted to 0|1 values if they're boolean
            if a.type_ == TYPE.boolean:
                a = SymbolTYPECAST.make_node(TYPE.ubyte, a, lineno)

            if b.type_ == TYPE.boolean:
                b = SymbolTYPECAST.make_node(TYPE.ubyte, b, lineno)

        # Check for constant non-numeric operations
        c_type = check.common_type(a, b)  # Resulting operation type or None
        if TYPE.is_numeric(c_type):  # there must be a common type for a and b
            if (
                check.is_numeric(a, b)
                and (check.is_const(a) or check.is_number(a))
                and (check.is_const(b) or check.is_number(b))
            ):
                if func is not None:
                    a = SymbolTYPECAST.make_node(c_type, a, lineno)  # ensure type
                    b = SymbolTYPECAST.make_node(c_type, b, lineno)  # ensure type
                    return SymbolNUMBER(func(a.value, b.value), type_=type_, lineno=lineno)

            if check.is_static(a, b):
                a = SymbolTYPECAST.make_node(c_type, a, lineno)  # ensure type
                b = SymbolTYPECAST.make_node(c_type, b, lineno)  # ensure type
                return SymbolCONSTEXPR(cls(operator, a, b, lineno, type_=type_, func=func), lineno=lineno)

        if check.is_string(a, b) and func is not None:  # Are they STRING Constants?
            if operator == "PLUS":
                return SymbolSTRING(func(a.value, b.value), lineno)

            return SymbolNUMBER(int(func(a.text, b.text)), type_=TYPE.ubyte, lineno=lineno)  # Convert to u8 (boolean)

        if operator in {"BNOT", "BAND", "BOR", "BXOR"}:
            if TYPE.is_decimal(c_type):
                c_type = TYPE.long_

        if a.type_ != b.type_ and TYPE.string in (a.type_, b.type_):
            c_type = a.type_  # Will give an error based on the fist operand

        if operator not in ("SHR", "SHL"):
            a = SymbolTYPECAST.make_node(c_type, a, lineno)
            b = SymbolTYPECAST.make_node(c_type, b, lineno)

        if a is None or b is None:
            return None

        if type_ is None:
            if operator in {"LT", "GT", "EQ", "LE", "GE", "NE", "AND", "OR", "XOR"}:
                type_ = TYPE.boolean
            else:
                type_ = c_type

        return cls(operator, a, b, type_=type_, lineno=lineno, func=func)
