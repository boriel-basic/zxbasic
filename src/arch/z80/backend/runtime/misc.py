# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .namespace import NAMESPACE


class MiscLabels:
    ASC = f"{NAMESPACE}.__ASC"
    CHR = f"{NAMESPACE}.CHR"
    PAUSE = f"{NAMESPACE}.__PAUSE"
    USR = f"{NAMESPACE}.USR"
    USR_STR = f"{NAMESPACE}.USR_STR"
    VAL = f"{NAMESPACE}.VAL"


REQUIRED_MODULES = {
    MiscLabels.ASC: "asc.asm",
    MiscLabels.CHR: "chr.asm",
    MiscLabels.PAUSE: "pause.asm",
    MiscLabels.USR: "usr.asm",
    MiscLabels.USR_STR: "usr_str.asm",
    MiscLabels.VAL: "val.asm",
}
