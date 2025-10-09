# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from abc import ABC, abstractmethod

__all__ = ("BackendInterface",)


class BackendInterface(ABC):
    """Generic Backend interface"""

    def __init__(self):
        self.init()

    @abstractmethod
    def init(self) -> None:
        """Initializes this module"""

    @staticmethod
    @abstractmethod
    def emit_prologue() -> list[str]:
        """Emits Program Start routine"""

    @staticmethod
    @abstractmethod
    def emit_epilogue() -> list[str]:
        """Emits Program End routine"""

    @abstractmethod
    def emit(self, *, optimize: bool = True) -> list[str]:
        """Begin converting each quad instruction to asm
        by iterating over the "mem" array, and called its
        associated function. Each function returns an array of
        ASM instructions
        """
