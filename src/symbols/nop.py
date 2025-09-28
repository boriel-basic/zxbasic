# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .block import SymbolBLOCK


class SymbolNOP(SymbolBLOCK):
    def __init__(self):
        super().__init__()

    def __bool__(self):
        return False

    def __nonzero__(self):
        return self.__bool__()
