# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.symbols.symbol_ import Symbol


class SymbolVARDECL(Symbol):
    """Defines a Variable declaration"""

    def __init__(self, entry):
        """The declared variable entry"""
        super().__init__(entry)

    @property
    def entry(self):
        return self.children[0]

    @property
    def type_(self):
        return self.entry.type_

    @property
    def mangled(self):
        return self.entry.mangled

    @property
    def size(self):
        return self.entry.size

    @property
    def default_value(self):
        return self.entry.default_value
