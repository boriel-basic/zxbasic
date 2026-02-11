# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import types
from collections.abc import Callable
from typing import Any, Final

from .tree import Tree

__all__: Final[tuple[str, ...]] = "Ast", "NodeVisitor"


# ----------------------------------------------------------------------
# Abstract Syntax Tree class
# ----------------------------------------------------------------------
class Ast(Tree):
    """Adds some methods for easier coding..."""

    __slots__: tuple[str, ...] = ()

    @property
    def token(self):
        return self.__class__


class NodeVisitor:
    node_type: type = Ast

    def visit(self, node):
        stack = [node]
        last_result = None

        while stack:
            try:
                stack_top = stack[-1]
                if isinstance(stack_top, types.GeneratorType):
                    stack.append(stack_top.send(last_result))
                    last_result = None
                elif isinstance(stack_top, self.node_type):
                    stack.pop()
                    stack.append(self._visit(stack_top))
                else:
                    last_result = stack.pop()
            except StopIteration:
                stack.pop()

        return last_result

    def _visit(self, node):
        meth = getattr(self, f"visit_{node.token}", self.generic_visit)
        return meth(node)

    def generic_visit(self, node: Ast):
        raise RuntimeError(f"No visit_{node.token}() method defined")

    def filter_inorder(
        self,
        node,
        filter_func: Callable[[Any], bool],
        child_selector: Callable[[Ast], bool] = lambda x: True,
    ):
        """Visit the tree inorder, but only those that return true for filter_func and visiting children which
        return true for child_selector.
        """
        visited = set()
        stack = [node]
        while stack:
            node = stack.pop()
            if node in visited:
                continue
            visited.add(node)
            if filter_func(node):
                yield self.visit(node)
            if isinstance(node, Ast) and child_selector(node):
                stack.extend(node.children[::-1])
