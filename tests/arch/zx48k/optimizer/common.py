# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from contextlib import contextmanager

from src.api.config import OPTIONS


@contextmanager
def mock_options_level(level: int):
    initial_level = OPTIONS.optimization_level

    try:
        OPTIONS.optimization_level = level
        yield
    finally:
        OPTIONS.optimization_level = initial_level
