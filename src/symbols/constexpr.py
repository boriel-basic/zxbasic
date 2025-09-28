# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import src
import src.api.global_ as gl
from src.symbols.symbol_ import Symbol

# ----------------------------------------------------------------------
# CONST Symbol object
# ----------------------------------------------------------------------


class SymbolCONSTEXPR(Symbol):
    """Defines a constant expression (not numerical, e.g. a Label or a @label,
    or a more complex one like @label + 5)
    """

    def __init__(self, expr, lineno):
        super().__init__(expr)
        self.lineno = lineno
        self._t = gl.optemps.new_t()

    @property
    def expr(self):
        return self.children[0]

    @expr.setter
    def expr(self, value):
        assert isinstance(value, Symbol)
        self.children = [value]

    @property
    def type_(self):
        return self.expr.type_

    def __str__(self):
        return str(self.expr)

    def __repr__(self):
        return str(self)

    @property
    def t(self):
        result = src.arch.target.Translator.traverse_const(self)
        return f"#{result}"
