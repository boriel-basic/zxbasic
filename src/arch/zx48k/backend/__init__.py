# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api.config import OPTIONS
from src.arch.z80.backend import (
    HI16,
    INITS,
    LO16,
    MEMINITS,
    REQUIRES,
    TMP_COUNTER,
    TMP_STORAGES,
    Float,
)
from src.arch.z80.backend import Backend as Z80Backend

__all__ = (
    "HI16",
    "INITS",
    "LO16",
    "MEMINITS",
    "REQUIRES",
    "TMP_COUNTER",
    "TMP_STORAGES",
    "Backend",
    "Float",
)


# ZXNext asm enabled by default for this arch
OPTIONS.zxnext = False


class Backend(Z80Backend):
    def init(self):
        # ZXNext asm enabled by default for this arch
        OPTIONS.zxnext = False
        super().init()
