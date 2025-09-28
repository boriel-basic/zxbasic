# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------


class PreprocError(Exception):
    """Denotes an exception in the preprocessor"""

    def __init__(self, msg, lineno):
        self.message = msg
        self.lineno = lineno

    def __str__(self):
        return self.message
