# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
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
