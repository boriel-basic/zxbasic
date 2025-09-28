# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api import check

from .symbol_ import Symbol


class SymbolBLOCK(Symbol):
    """Defines a block of code."""

    def __init__(self, *nodes):
        super().__init__(*(x for x in nodes if not check.is_null(x)))

    @classmethod
    def make_node(cls, *args):
        """Creates a chain of code blocks."""
        result = SymbolBLOCK()
        result.append(*args)
        return result

    def __getitem__(self, item):
        return self.children[item]

    def __len__(self):
        return len(self.children)

    def __eq__(self, other):
        if not isinstance(other, SymbolBLOCK):
            return False

        return len(self) == len(other) and all(x == y for x, y in zip(self, other))

    def __hash__(self):
        return id(self)

    def pop(self, pos: int = -1) -> Symbol:
        return self.children.pop(pos)

    def append(self, *args):
        for arg in args:
            if check.is_null(arg):
                continue
            assert isinstance(arg, Symbol), f"Invalid argument '{arg}'"
            if arg.token == "BLOCK":
                self.append(*arg.children)
            else:
                self.children.append(arg)
