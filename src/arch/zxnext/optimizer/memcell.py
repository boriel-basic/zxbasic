# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
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
