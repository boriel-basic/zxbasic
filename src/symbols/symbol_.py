# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------
from __future__ import annotations

from collections import Counter

import src.api.global_
from src.ast import Ast, Tree


class Symbol(Ast):
    """Symbol object to store everything related to a symbol."""

    __slots__ = "_required_by", "_requires"

    _t: str | None = None

    def __init__(self, *children):
        super().__init__()
        for child in children:
            assert isinstance(child, Symbol), f"{child} is not Symbol"
            self.append_child(child)

        self._required_by: Counter = Counter()  # Symbols that depends on this one
        self._requires: Counter = Counter()  # Symbols this one depends on

    @property
    def required_by(self) -> Counter:
        return self._required_by

    @property
    def requires(self) -> Counter:
        return Counter(self._requires)

    def mark_as_required_by(self, other: Symbol):
        if self is other:
            return

        self._required_by.update([other])
        other._requires.update([self])

        for sym in other.required_by:
            sym.add_required_symbol(self)

    def add_required_symbol(self, other: Symbol):
        if self is other:
            return

        self._requires.update([other])
        other._required_by.update([self])

        for sym in other.requires:
            sym.mark_as_required_by(self)

    @property
    def token(self) -> str:
        """token = AST Symbol class name, removing the 'Symbol' prefix."""
        return self.__class__.__name__[6:]  # e.g. 'CALL', 'NUMBER', etc...

    def __str__(self):
        return self.token

    def __repr__(self):
        return str(self)

    @property
    def t(self) -> str:
        if self._t is None:
            self._t = src.api.global_.optemps.new_t()

        return self._t

    @property
    def is_needed(self) -> bool:
        return len(self.required_by) > 0

    def get_parent(self, type_) -> Tree | None:
        """Traverse parents until finding one
        of type type_ or None if not found.
        If a cycle is detected an undetermined value is returned as parent.
        """
        visited = set()
        parent = self.parent
        while parent is not None and parent not in visited:
            visited.add(parent)
            if isinstance(parent, type_):
                return parent
            parent = parent.parent

        return parent
