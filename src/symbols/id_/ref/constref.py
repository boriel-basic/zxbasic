# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api.constants import CLASS
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.id_.ref.symbolref import SymbolRef
from src.symbols.symbol_ import Symbol


class ConstRef(SymbolRef):
    __slots__ = ("_value",)

    def __init__(self, parent: SymbolID, default_value: Symbol):
        super().__init__(parent)
        assert default_value.token in ("CONSTEXPR", "NUMBER", "CONST", "STRING")
        self._value = default_value

    @property
    def token(self) -> str:
        return "CONST"

    @property
    def class_(self) -> CLASS:
        return CLASS.const

    @property
    def t(self) -> str:
        return self._value.t

    @property
    def value(self):
        if self._value.token in ("NUMBER", "CONST", "STRING"):
            return self._value.value

        return self.t

    @property
    def symbol(self) -> Symbol:
        return self._value
