#!/usr/bin/env python3

# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from .tzx import TZX


class TAP(TZX):
    """Derived from TZX. Implements TAP output"""

    def __init__(self):
        """Initializes the object with standard header"""
        super(TAP, self).__init__()
        self.output = bytearray()  # Restarts the output

    def standard_block(self, bytes_):
        """Adds a standard block of bytes. For TAP files, it's just the
        Low + Hi byte plus the content (here, the bytes plus the checksum)
        """
        self.out(self.LH(len(bytes_) + 1))  # + 1 for CHECKSUM byte

        checksum = 0
        for i in bytes_:
            checksum ^= int(i) & 0xFF
            self.out(i)

        self.out(checksum)


if __name__ == "__main__":
    """Sample test if invoked from command line"""
    t = TAP()
    t.save_code("taptest", 16384, range(255))
    t.dump("tzxtest.tap")
