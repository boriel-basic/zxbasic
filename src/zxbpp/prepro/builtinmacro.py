# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from collections.abc import Callable

from src.zxbpp.prepro import DefinesTable

from .id_ import ID
from .macrocall import MacroCall


class BuiltinMacro(ID):
    """A call to a builtin macro like __FILE__ or __LINE__
    Every time the macro() is called, the macro returns
    its value.
    """

    def __init__(self, macro_name: str, func: Callable[[MacroCall | None], str]):
        super().__init__(fname="", lineno=0, id_=macro_name)
        self.func = func

    def __call__(self, symbolTable: DefinesTable | None = None, macro: MacroCall | None = None) -> str:
        return self.func(macro)
