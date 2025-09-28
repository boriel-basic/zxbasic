# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from functools import cached_property

from src.arch.z80.optimizer.memcell import MemCell as MemCellZ80

__all__ = ("MemCell",)


class MemCell(MemCellZ80):
    @cached_property
    def destroys(self) -> set[str]:
        if self.is_label:
            return set()

        if self.inst == "mul":
            return {"d", "e"}

        return super().destroys

    @cached_property
    def requires(self) -> set[str]:
        if self.inst == "mul":
            return {"d", "e"}

        return super().requires
