# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .symbol_ import Symbol


class SymbolARRAYDECL(Symbol):
    """Defines an Array declaration"""

    def __init__(self, entry):
        super().__init__(entry)

    @property
    def name(self):
        return self.entry.name

    @property
    def mangled(self):
        return self.entry.mangled

    @property
    def entry(self):
        return self.children[0]

    @property
    def type_(self):
        return self.entry.type_

    @property
    def size(self):
        """Total memory size of array cells"""
        return self.type_.size * self.count

    @property
    def count(self):
        """Total number of array cells"""
        return self.entry.count

    @property
    def memsize(self):
        """Total array cell + indexes size"""
        return self.entry.memsize

    @property
    def bounds(self):
        return self.entry.bounds

    def __str__(self):
        return "%s(%s)" % (self.entry.name, self.bounds)

    def __repr__(self):
        return str(self)
