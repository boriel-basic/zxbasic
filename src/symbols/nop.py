# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .block import SymbolBLOCK


class SymbolNOP(SymbolBLOCK):
    def __init__(self):
        super().__init__()

    def __bool__(self):
        return False

    def __nonzero__(self):
        return self.__bool__()
