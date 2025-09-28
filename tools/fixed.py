# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import sys

number = float(sys.argv[1])
number1 = 0xFFFFFFFF & int(number * 2**16)
DE = number1 >> 16
HL = number1 & 0xFFFF

print("%f = %04X : %04X" % (number, DE, HL))
