# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from src.api import check, errmsg
from src.api.errmsg import error
from src.symbols.id_ import SymbolID
from src.symbols.number import SymbolNUMBER
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import SymbolTYPE
from src.symbols.type_ import Type as TYPE


class SymbolTYPECAST(Symbol):
    """Defines a typecast operation."""

    def __init__(self, new_type, operand, lineno):
        assert isinstance(new_type, SymbolTYPE)
        super().__init__(operand)
        self.lineno = lineno
        self.type_ = new_type

    # The converted (typecast) node
    @property
    def operand(self):
        return self.children[0]

    @operand.setter
    def operand(self, operand_):
        assert isinstance(operand_, Symbol)
        self.children[0] = operand_

    @classmethod
    def make_node(cls, new_type: SymbolTYPE, node: Symbol, lineno: int):
        """Creates a node containing the type cast of
        the given one. If new_type == node.type, then
        nothing is done, and the same node is
        returned.

        Returns None on failure (and calls syntax_error)
        """
        assert isinstance(new_type, SymbolTYPE)

        # None (null) means the given AST node is empty (usually an error)
        if node is None:
            return None  # Do nothing. Return None

        assert isinstance(node, Symbol), "<%s> is not a Symbol" % node
        # The source and dest types are the same
        if new_type == node.type_:
            return node  # Do nothing. Return as is

        # TODO: Create a base scalar type
        if node.token == "VARARRAY":
            if new_type.size == node.type_.size and TYPE.string not in (new_type, node.type_):
                return node

            assert isinstance(node, SymbolID)
            error(lineno, f"Array {node.name} type does not match parameter type")
            return None

        STRTYPE = TYPE.string
        # Typecasting, at the moment, only for number
        if node.type_ == STRTYPE:
            error(lineno, "Cannot convert string to a value. Use VAL() function")  # TODO: Improve error message
            return None

        # Converting from string to number is done by STR
        if new_type == STRTYPE:
            error(lineno, "Cannot convert value to string. Use STR() function")  # TODO: Improve error message
            return None

        # If the given operand is a constant, perform a static typecast
        if check.is_CONST(node):
            node.expr = cls(new_type, node.expr, lineno)
            return node

        if not check.is_number(node) and not check.is_const(node):
            return cls(new_type, node, lineno)

        # It's a number. So let's convert it directly
        if check.is_const(node):
            node = SymbolNUMBER(node.value, node.lineno, node.type_)

        if new_type == TYPE.boolean:
            node.value = int(bool(node.value))
            new_type = TYPE.ubyte  # For the moment we'll use UByte externally
        elif new_type.is_basic and not TYPE.is_integral(new_type):  # not an integer
            node.value = float(node.value)
        else:  # It's an integer
            new_val = int(node.value) & ((1 << (8 * new_type.size)) - 1)  # Mask it

            if node.value >= 0 and node.value != new_val:
                errmsg.warning_conversion_lose_digits(node.lineno)
                node.value = new_val
            elif (
                node.value < 0 and (1 << (new_type.size * 8)) + node.value != new_val
            ):  # Test for positive to negative coercion
                errmsg.warning_conversion_lose_digits(node.lineno)
                node.value = new_val - (1 << (new_type.size * 8))

        node.type_ = new_type
        return node
