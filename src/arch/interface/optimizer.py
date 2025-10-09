# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from abc import ABC, abstractmethod


class OptimizerInterface(ABC):
    """Implements the Peephole Optimizer"""

    @abstractmethod
    def init(self) -> None:
        pass

    @abstractmethod
    def optimize(self, initial_memory: list[str]) -> str:
        """This will remove useless instructions"""
        pass
