# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import re
from collections.abc import Iterable
from typing import Any, NamedTuple, Self

from src.api.errmsg import error
from src.ast_ import Ast
from src.ast_.exceptions import NotAnAstError
from src.zxbasm.label import Label

RE_ID = "^[.a-zA-Z_][.a-zA-Z0-9_]*$"


class Container(NamedTuple):
    """Single class container"""

    item: Any
    lineno: int


class Expr(Ast):
    """A class derived from AST that will
    recursively parse its nodes and return the value
    """

    ignore = True  # Class flag
    # operators
    funct = {
        "-": lambda x, y: x - y,
        "+": lambda x, y: x + y,
        "*": lambda x, y: x * y,
        "/": lambda x, y: x // y,
        "^": lambda x, y: x**y,
        "%": lambda x, y: x % y,
        "&": lambda x, y: x & y,
        "|": lambda x, y: x | y,
        "~": lambda x, y: x ^ y,
        "<<": lambda x, y: x << y,
        ">>": lambda x, y: x >> y,
    }

    def __init__(self, symbol=None):
        """Initializes ancestor attributes and ignore flags."""
        super().__init__()
        self.symbol = symbol

    @property
    def left(self) -> Expr | None:
        if self.children:
            return self.children[0]

        return None

    @property
    def right(self) -> Expr | None:
        if len(self.children) > 1:
            return self.children[1]

        return None

    def eval(self) -> tuple | list | int | None:
        """Recursively evals the node. Exits with an error if not resolved."""
        Expr.ignore = False
        result = self.try_eval()
        Expr.ignore = True

        return result

    def try_eval(self) -> tuple | list | int | None:
        """Recursively evals the node. Returns None if it is still unresolved."""
        item = self.symbol.item

        if isinstance(item, int):
            return item

        if isinstance(item, Label):
            if item.defined:
                if isinstance(item.value, Expr):
                    return item.value.try_eval()

                return item.value

            if Expr.ignore:
                return None

            # Try to resolve into the global namespace
            error(self.symbol.lineno, "Undefined label '%s'" % item.name)
            return None

        try:
            if isinstance(item, tuple):
                return tuple([x.try_eval() for x in item])

            if isinstance(item, list):
                return [x.try_eval() for x in item]

            if item == "-" and len(self.children) == 1:
                return -self.left.try_eval()

            if item == "+" and len(self.children) == 1:
                return self.left.try_eval()

            try:
                return self.funct[item](self.left.try_eval(), self.right.try_eval())

            except ZeroDivisionError:
                error(self.symbol.lineno, "Division by 0")

            except KeyError:
                pass

        except TypeError:
            pass

        return None

    @classmethod
    def makenode(cls, symbol, *nexts: Self) -> Self:
        """Stores the symbol in an AST instance,
        and left and right to the given ones
        """
        result = cls(symbol)
        for i in nexts:
            if i is None:
                continue

            if not isinstance(i, cls):
                raise NotAnAstError(i)

            result.append_child(i)

        return result

    def as_rpn(self) -> tuple[str | int, ...]:
        """Returns the expression in reverse polish notation"""
        result = []
        item = self.symbol.item.name if isinstance(self.symbol.item, Label) else self.symbol.item
        if item == "+" and self.right is None:
            return self.left.as_rpn()

        if item == "-" and self.right is None:
            result = [0]

        if self.left is not None:
            result.extend(self.left.as_rpn())

        if self.right is not None:
            result.extend(self.right.as_rpn())

        result.append(item)
        return tuple(result)

    @classmethod
    def from_rpn(cls, rpn: Iterable[str | int]) -> Self:
        """Returns an AST instance from a reverse polish notation"""
        stack: list[Self] = []

        for s in rpn:
            if isinstance(s, int):
                stack.append(cls(Container(lineno=0, item=s)))
                continue

            if s in cls.funct:  # an operator
                right = stack.pop()
                left = stack.pop()
                expr = cls(Container(lineno=0, item=s))
                expr.append_child(left)
                expr.append_child(right)
                stack.append(expr)
                continue

            if isinstance(s, str) and re.match(RE_ID, s):
                s = re.sub(r"\.+", ".", s).rstrip(".")  # Remove duplicated dots
                stack.append(cls(Container(lineno=0, item=Label(s, lineno=0))))

            raise ValueError("Invalid RPN expression")

        assert len(stack) == 1, "Invalid RPN expression"
        return stack[0]
