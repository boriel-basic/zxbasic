# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.arch.z80.optimizer import Optimizer as OptimizerZ80

from .basicblock import BasicBlock

__all__ = ("Optimizer",)


class Optimizer(OptimizerZ80):
    _BASICBLOCK_TYPE: type[BasicBlock] = BasicBlock
