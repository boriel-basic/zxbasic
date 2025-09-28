# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from __future__ import annotations

from src.api.constants import CLASS
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import Type


class SymbolSTRING(Symbol):
    """Defines a string value."""

    value: str

    def __init__(self, value: SymbolSTRING | str, lineno: int):
        assert isinstance(value, (str, SymbolSTRING))
        super().__init__()
        self.value = value.value if isinstance(value, SymbolSTRING) else value
        self.type_ = Type.string
        self.lineno = lineno
        self.class_ = CLASS.const
        self._t: str = self.value

    @property
    def t(self) -> str:
        return self._t

    @t.setter
    def t(self, value: str):
        assert isinstance(value, str)
        self._t = value

    def __str__(self):
        return self.value

    def __repr__(self):
        return '"%s"' % str(self)

    def __eq__(self, other: object):
        if isinstance(other, str):
            return self.value == other

        assert isinstance(other, SymbolSTRING)
        return self.value == other.value

    def __gt__(self, other: str | SymbolSTRING):
        if isinstance(other, str):
            return self.value > other

        assert isinstance(other, SymbolSTRING)
        return self.value > other.value

    def __lt__(self, other: str | SymbolSTRING):
        if isinstance(other, str):
            return self.value < other

        assert isinstance(other, SymbolSTRING)
        return self.value < other.value

    def __hash__(self):
        return hash(self.value)

    def __ne__(self, other):
        return not self.__eq__(other)

    def __ge__(self, other):
        return not self.__lt__(other)

    def __le__(self, other):
        return not self.__gt__(other)
