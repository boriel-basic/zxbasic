# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.symbols.symbol_ import Symbol


class SymbolSENTENCE(Symbol):
    """Defines a BASIC SENTENCE object. e.g. 'BORDER'."""

    def __init__(self, lineno: int, filename: str, keyword: str, *args, is_sentinel=False):
        """Params:
        - keyword: BASIC sentence token like 'BORDER', 'PRINT', ...
        - sentinel: whether this sentence was automagically added by the compiler
            (i.e. a RETURN "" in a string function when the user does not return anything)
        """
        super().__init__(*(x for x in args if x is not None))
        self.keyword = keyword
        self.lineno = lineno
        self.filename = filename
        self.is_sentinel = is_sentinel

    @property
    def args(self):
        return self.children

    @property
    def token(self):
        """Sentence takes it's token from the keyword not from it's name"""
        return self.keyword
