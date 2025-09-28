# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from collections import UserDict

from .errors import DuplicatedLabelError
from .labelinfo import LabelInfo


class LabelsDict(UserDict[str, LabelInfo]):
    """A dictionary of labels where an existing label cannot be overwritten"""

    def __setitem__(self, key: str, value: LabelInfo) -> None:
        if key in self.data:
            raise DuplicatedLabelError(key)

        self.data[key] = value
