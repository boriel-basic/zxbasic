# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import sys
from typing import Final

MINIMUM_REQUIRED_PYTHON_VERSION: Final[tuple[int, int]] = (3, 11)


def init():
    if sys.version_info < MINIMUM_REQUIRED_PYTHON_VERSION:
        sys.exit("Python %i.%i or later is required." % MINIMUM_REQUIRED_PYTHON_VERSION)


init()
