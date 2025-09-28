# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .basicblock import BasicBlock


@dataclass
class LabelInfo:
    """Class describing label information
    Stores the label name, the address counter into memory (rather useless)
    and which basic block contains it.
    """

    label: str
    addr: int  # Memory address or 0
    basic_block: BasicBlock | None = None  # Basic Block this label is in
    position: int = 0  # Position within the Basic Block
    used_by: set[BasicBlock] = field(default_factory=set)  # Which BB uses this label, if any
