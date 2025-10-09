# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from collections.abc import Callable
from dataclasses import dataclass

from .quad import Quad

__all__ = ("ICInfo",)


@dataclass(frozen=True)
class ICInfo:
    nargs: int
    func: Callable[[Quad], list[str]]
