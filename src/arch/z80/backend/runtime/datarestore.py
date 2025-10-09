# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .namespace import NAMESPACE


class DataRestoreLabels:
    READ = f"{NAMESPACE}.__READ"
    RESTORE = f"{NAMESPACE}.__RESTORE"


REQUIRED_MODULES = {
    DataRestoreLabels.READ: "read_restore.asm",
    DataRestoreLabels.RESTORE: "read_restore.asm",
}
