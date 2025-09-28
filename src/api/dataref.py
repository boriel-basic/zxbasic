# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from dataclasses import dataclass
from typing import Any

from src.symbols.id_ import SymbolID


@dataclass(frozen=True)
class DataRef:
    label: SymbolID
    datas: list[Any]

    def __post_init__(self):
        assert self.label.token == "LABEL"

    def __iter__(self):
        return (x for x in [self.label, self.datas])
