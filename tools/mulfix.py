#!/usr/bin/env python

# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import sys


def fixed(number):
    number = int(number * 2**16)
    return 0xFFFF & (number >> 16), number & 0xFFFF


number1, number2 = float(sys.argv[1]), float(sys.argv[2])
number1a = 0xFFFFFFFF & int(number1 * 2**16)
number2a = 0xFFFFFFFF & int(number2 * 2**16)

print("%f * %f = %f" % (number1, number2, number1 * number2))

h, l = fixed(number1)
print("%f = %X : %X" % (number1, h, l))
h, l = fixed(number2)
print("%f = %X : %X" % (number2, h, l))
h, l = fixed(number1 * number2)
print("%f = %X : %X" % (number1 * number2, h, l))

number3 = number1a * number2a
number3 = (number3 >> 16) & 0xFFFFFFFF
print("%X %f" % (number3, number3 / 2.0**16))
