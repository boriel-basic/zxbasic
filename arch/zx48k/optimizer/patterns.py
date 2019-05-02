# -*- coding: utf-8 -*-

import re

__doc__ = """ Patterns to match against generated ASM code.
"""


# matches an integer in signed decimal, hexadecimal ($XXXX, or XXXXh) or binary (nnnnB)
RE_NUMBER = re.compile(r'^([-+]?[0-9]+|$[A-Fa-f0-9]+|[0-9][A-Fa-f0-9]*[Hh]|%[01]+|[01]+[bB])$')

# matches an indexed register operand like (IX + 3) or (iy - 4). Case insensitive
RE_INDIR_OPER = re.compile(r'\([ \t]*[Ii][XxYy][ \t]*[-+][ \t]*[0-9]+[ \t]*\)')

# captures the offset of the indexed register operand. ie (ix+5) => +, 5
RE_IXIND_OPER = re.compile(r'[iI][xXyY][ \t]*([-+])(?:[ \t]*)([0-9]+)?')

# captures the register, the operator and the operand
RE_IDX = re.compile(r'^([iI][xXyY])[ ]*([-+])[ \t]*(.*)$')

# captures a label definition (simply an identifier ending with a colon)
RE_LABEL = re.compile(r'^[ \t]*[_a-zA-Z][a-zA-Z\d]*:')

# matches and captures (de) or (hl)
RE_INDIR16 = re.compile(r'[ \t]*\([ \t]*([dD][eE]|[hH][lL])[ \t]*\)[ \t]*')

# matches the '(c)' register in instruction out (c), ...
RE_OUTC = re.compile(r'[ \t]*\([ \t]*[cC]\)')

# matches an identifier
RE_ID = re.compile(r'[.a-zA-Z_][.a-zA-Z_0-9]*')

# matches a pragma line
RE_PRAGMA = re.compile(r'^#[ \t]?pragma[ \t]opt[ \t]')
