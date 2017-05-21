#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4

from z80 import Opcode, Z80SET
from api.errors import Error
import re

# Reg. Exp. for counting N args in an asm mnemonic
ARGre = re.compile(r'\bN+\b')

Z80_re = {}  # Reg. Expr dictionary to cache them

Z80_8REGS = ('A', 'B', 'C', 'D', 'E', 'H', 'L',
             'IXh', 'IYh', 'IXl', 'IYl', 'I', 'R')

Z80_16REGS = {'AF': ('A', 'F'), 'BC': ('B', 'C'), 'DE': ('D', 'E'),
              'HL': ('H', 'L'), 'SP': (),
              'IX': ('IXh', 'IXl'), 'IY': ('IYh', 'IYl')
              }


def num2bytes(x, bytes):
    """ Returns x converted to a little-endian t-uple of bytes.
    E.g. num2bytes(255, 4) = (255, 0, 0, 0)
    """
    if not isinstance(x, int):  # If it is another "thing", just return ZEROs
        return tuple([0] * bytes)

    x = x & ((2 << (bytes * 8)) - 1)  # mask the initial value
    result = ()

    for i in range(bytes):
        result += (x & 0xFF,)
        x >>= 8

    return result


class InvalidMnemonicError(Error):
    """ Exception raised when an invalid Mnemonic has been emmitted.
    """

    def __init__(self, mnemo):
        self.msg = "Invalid mnemonic '%s'" % mnemo
        self.mnemo = mnemo


class InvalidArgError(Error):
    """ Exception raised when an invalid argument has been emmitted.
    """

    def __init__(self, arg):
        self.msg = "Invalid argument '%s'. It must be an integer." % str(arg)
        self.mnemo = arg


class InternalMismatchSizeError(Error):
    """ Exception raised when an invalid instruction length has been emmitted.
    """

    def __init__(self, current_size, asm):
        a = '' if current_size == 1 else 's'
        b = '' if asm.size == 1 else 's'

        self.msg = ("Invalid instruction [%s] size (%i byte%s). "
                    "It should be %i byte%s." % (asm.asm, current_size, a,
                                                 asm.size, b))
        self.current_size = current_size
        self.asm = asm


class AsmInstruction(Opcode):
    """ Derivates from Opcode. This one checks the nmenomic
    is valid. """

    def __init__(self, asm, arg=None):
        """ Parses the given asm instruction and validates
        it against the Z80SET table. Raises InvalidMnemonicError
        if not valid.

        It uses the Z80SET global dictionary. Args is an optional
        argument (it can be a Label object or a value)
        """
        if isinstance(arg, list):
            arg = tuple(arg)

        if arg is None:
            arg = ()

        if arg is not None and not isinstance(arg, tuple):
            arg = (arg,)

        asm = asm.split(';', 1)  # Try to get comments out, if any
        if len(asm) > 1:
            self.comments = ';' + asm[1]
        else:
            self.comments = ''

        asm = asm[0]
        if asm.upper() not in Z80SET.keys():
            raise InvalidMnemonicError(asm)

        self.mnemo = asm.upper()
        Z80 = Z80SET[self.mnemo]

        self.asm = asm
        self.size = Z80.size
        self.T = Z80.T
        self.opcode = Z80.opcode
        self.argbytes = tuple([len(x) for x in ARGre.findall(asm)])
        self.arg = arg
        self.arg_num = len(ARGre.findall(asm))

    def argval(self):
        """ Returns the value of the arg (if any) or None.
        If the arg. is not an integer, an error be triggered.
        """
        if self.arg is None:
            return None

        for x in self.arg:
            if not isinstance(x, int):
                raise InvalidArgError(self.arg)

        return self.arg

    def bytes(self):
        """ Returns a t-uple with instruction bytes (integers)
        """
        result = []
        op = self.opcode.split(' ')
        argi = 0

        while op:
            q = op.pop(0)

            if q == 'XX':
                for k in range(self.argbytes[argi] - 1):
                    op.pop(0)

                result.extend(num2bytes(self.argval()[argi], self.argbytes[argi]))
                argi += 1
            else:
                result.append(int(q, 16))  # Add opcode

        if len(result) != self.size:
            raise InternalMismatchSizeError(len(result), self)

        return result

    def __str__(self):
        return self.asm
