#!/usr/bin/env python3

# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import os
import sys

sys.path.append(os.path.dirname(__file__))

from src import zxbpp

if __name__ == "__main__":
    sys.exit(zxbpp.entry_point())
