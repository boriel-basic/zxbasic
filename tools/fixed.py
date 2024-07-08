#!/usr/bin/env python

# A program that displays fixed point numbers in hexa

import sys

number = float(sys.argv[1])
number1 = 0xFFFFFFFF & int(number * 2**16)
DE = number1 >> 16
HL = number1 & 0xFFFF

print("%f = %04X : %04X" % (number, DE, HL))
