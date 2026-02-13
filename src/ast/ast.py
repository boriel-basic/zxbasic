# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------
from collections.abc import Callable, Generator
from typing import Any, Final

from .tree import Tree
from .visitor import GenericNodeVisitor

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


class NodeVisitor(GenericNodeVisitor[Ast]):
    def _visit(self, node: Ast):
        meth: Callable[[Ast], Generator[Ast | Any, Any, None]] = getattr(
            self,
            f"visit_{node.token}",
            self.generic_visit,
        )
        return meth(node)

    def generic_visit(self, node: Ast) -> Generator[Ast | Any, Any, None]:
        for i, child in enumerate(node.children):
            node.children[i] = yield self.visit(child)

        yield node
