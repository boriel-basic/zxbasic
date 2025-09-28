# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.arch.z80.optimizer import Optimizer as OptimizerZ80

from .basicblock import BasicBlock

__all__ = ("Optimizer",)


class Optimizer(OptimizerZ80):
    _BASICBLOCK_TYPE: type[BasicBlock] = BasicBlock
