# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import sys
from typing import Final

MINIMUM_REQUIRED_PYTHON_VERSION: Final[tuple[int, int]] = (3, 11)


def init():
    if sys.version_info < MINIMUM_REQUIRED_PYTHON_VERSION:
        sys.exit("Python %i.%i or later is required." % MINIMUM_REQUIRED_PYTHON_VERSION)


init()
