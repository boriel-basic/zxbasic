# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

__doc__ = """This module is a singleton instance that contains
a mapping of constant Strings to Labels.
"""
from collections import defaultdict
from typing import Final

from src.api import tmp_labels

STRING_LABELS: Final[dict[str, str]] = defaultdict(tmp_labels.tmp_label)


def reset():
    """Initializes this module"""
    STRING_LABELS.clear()


def add_string_label(string: str) -> str:
    """Maps ("folds") the given string, returning a unique label ID.
    This allows several constant labels to be initialized to the same address
    thus saving memory space.
    :param string: the string to map
    :return: the unique label ID
    """
    return STRING_LABELS[string]
