# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.symbols.bound import SymbolBOUND
from src.symbols.symbol_ import Symbol


class SymbolBOUNDLIST(Symbol):
    """Defines a bound list for an array"""

    def __init__(self, *bounds):
        for bound in bounds:
            assert isinstance(bound, SymbolBOUND)

        super().__init__(*bounds)

    def __len__(self):  # Number of bounds:
        return len(self.children)

    def __getitem__(self, key):
        return self.children[key]

    def __str__(self):
        return "(%s)" % ", ".join(str(x) for x in self)

    @classmethod
    def make_node(cls, node: Symbol | None, *args):
        """Creates an array BOUND LIST."""
        if node is None:
            return cls.make_node(SymbolBOUNDLIST(), *args)

        if node.token != "BOUNDLIST":
            return cls.make_node(None, node, *args)

        for arg in args:
            if arg is None:
                continue
            node.append_child(arg)

        return node
