# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .symbol_ import Symbol


class SymbolASM(Symbol):
    """Defines an ASM sentence"""

    def __init__(self, asm: str, lineno: int, filename: str, is_sentinel: bool = False):
        super().__init__()
        self.asm = asm
        self.lineno = lineno
        self.filename = filename
        self.is_sentinel = is_sentinel
