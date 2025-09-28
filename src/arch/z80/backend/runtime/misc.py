# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
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
