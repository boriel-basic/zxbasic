# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
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
