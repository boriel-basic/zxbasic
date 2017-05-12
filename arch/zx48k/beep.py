#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

__doc___ = """This library converts duration,pitch for a beep
from floating point to HL,DE Integers.
"""


class BeepError(BaseException):
    """Returned when invalid pitch specified (e.g. Out of Range)
    """

    def __init__(self, msg='Invalid beep parameters'):
        self.message = msg

    def __str__(self):
        return self.message


# Pitch (frequencies) tables
TABLE = [261.625565290,  # C
         277.182631135,
         293.664768100,
         311.126983881,
         329.627557039,
         349.228231549,
         369.994422674,
         391.995436072,
         415.304697513,
         440.000000000,
         466.163761616,
         493.883301378]


def getDEHL(duration, pitch):
    """Converts duration,pitch to a pair of unsigned 16 bit integers,
    to be loaded in DE,HL, following the ROM listing.
    Returns a t-uple with the DE, HL values.
    """
    intPitch = int(pitch)
    fractPitch = pitch - intPitch  # Gets fractional part
    tmp = 1 + 0.0577622606 * fractPitch
    if not -60 <= intPitch <= 127:
        raise BeepError('Pitch out of range: must be between [-60, 127]')

    if duration < 0 or duration > 10:
        raise BeepError('Invalid duration: must be between [0, 10]')

    A = intPitch + 60
    B = -5 + int(A / 12)  # -5 <= B <= 10
    A %= 0xC  # Semitones above C

    frec = TABLE[A]
    tmp2 = tmp * frec
    f = tmp2 * 2.0 ** B

    DE = int(0.5 + f * duration - 1)
    HL = int(0.5 + 437500.0 / f - 30.125)
    return DE, HL


if __name__ == '__main__':
    # Simple test
    print(getDEHL(1, 0), [hex(x) for x in getDEHL(1, 0)])
    print(getDEHL(5, 0), [hex(x) for x in getDEHL(5, 0)])
    print(getDEHL(1.5, 15.0), [hex(x) for x in getDEHL(1.5, 15.0)])
    print(getDEHL(1.5, 17.0), [hex(x) for x in getDEHL(1.5, 17.0)])
