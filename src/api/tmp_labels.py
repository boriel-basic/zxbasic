# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api import global_ as gl

LABEL_COUNTER = 0

# GENERATED labels __LABELXX
TMP_LABELS: set[str] = set()


def tmp_label() -> str:
    """Generates a new unique temporary label, like .LABEL.__LABEL01"""
    global LABEL_COUNTER
    global TMP_LABELS

    result = f"{gl.LABELS_NAMESPACE}.__LABEL{LABEL_COUNTER}"
    TMP_LABELS.add(result)
    LABEL_COUNTER += 1

    return result


def reset():
    """Resets this module"""
    global LABEL_COUNTER
    global TMP_LABELS

    LABEL_COUNTER = 0
    TMP_LABELS.clear()
