# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .symbol_ import Symbol


class SymbolASM(Symbol):
    """Defines an ASM sentence"""

    def __init__(self, asm: str, lineno: int, filename: str, is_sentinel: bool = False):
        super().__init__()
        self.asm = asm
        self.lineno = lineno
        self.filename = filename
        self.is_sentinel = is_sentinel
