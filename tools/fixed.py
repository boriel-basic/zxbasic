# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import sys

number = float(sys.argv[1])
number1 = 0xFFFFFFFF & int(number * 2**16)
DE = number1 >> 16
HL = number1 & 0xFFFF

print("%f = %04X : %04X" % (number, DE, HL))
