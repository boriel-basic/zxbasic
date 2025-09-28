# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from __future__ import annotations

from collections.abc import Iterable

from src.symbols.argument import SymbolARGUMENT
from src.symbols.symbol_ import Symbol


class SymbolARGLIST(Symbol, Iterable[SymbolARGUMENT]):
    """Defines a list of arguments in a function call or array access"""

    @property
    def args(self):
        return self.children

    @args.setter
    def args(self, value):
        for i in value:
            assert isinstance(value, SymbolARGUMENT)
            self.append_child(i)

    def __getitem__(self, range_):
        return self.args[range_]

    def __setitem__(self, range_, value: SymbolARGUMENT):
        assert isinstance(value, SymbolARGUMENT)
        self.children[range_] = value

    def __iter__(self):
        return iter(self.args)

    def __str__(self):
        return "(%s)" % (", ".join(str(x) for x in self.args))

    def __repr__(self):
        return str(self)

    def __len__(self):
        return len(self.args)

    @classmethod
    def make_node(cls, node: SymbolARGLIST | SymbolARGUMENT | None, *args: SymbolARGUMENT):
        """This will return a node with an argument_list."""
        if node is None:
            node = cls()

        assert isinstance(node, SymbolARGUMENT) or isinstance(node, cls)

        if isinstance(node, SymbolARGUMENT):
            return cls.make_node(None, node, *args)

        for arg in args:
            assert isinstance(arg, SymbolARGUMENT)
            node.append_child(arg)

        return node
