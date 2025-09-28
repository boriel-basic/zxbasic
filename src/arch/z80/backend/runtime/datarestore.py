# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
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
