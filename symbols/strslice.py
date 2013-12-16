#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from api.constants import TYPE

from symbol_ import Symbol
from number import SymbolNUMBER as NUMBER
from typecast import SymbolTYPECAST as TYPECAST
from binary import SymbolBINARY as BINARY
from string_ import SymbolSTRING as STRING

from api.config import OPTIONS
from api.check import check_type
from api.check import is_number

from api.constants import MIN_STRSLICE_IDX
from api.constants import MAX_STRSLICE_IDX

class SymbolSTRSLICE(Symbol):
    ''' Defines a string slice
    '''
    def __init__(self, string, lower, upper, lineno):
        Symbol.__init__(self, string, lower, upper)
        self.lineno = lineno
        self.type_ = TYPE.string

    @property
    def string(self):
        return self.children[0]

    @string.setter
    def string(self, value):
        self.children[0] = value

    @property
    def lower(self):
        return self.children[1]

    @lower.setter
    def lower(self, value):
        self.children[1] = value

    @property
    def upper(self):
        return self.children[2]

    @upper.setter
    def upper(self, value):
        self.children[2] = value

    @classmethod
    def make_node(clss, lineno, s, lower, upper):
        ''' Creates a node for a string slice. S is the string expression Tree.
        Lower and upper are the bounds, if lower & upper are constants, and
        s is also constant, s, then a string constant is returned.

        If lower > upper, an empty string is returned.
        '''
        if not check_type(lineno, TYPE.string, s):
            return None

        lo = up = None
        base = NUMBER(OPTIONS.string_base.value, lineno=lineno)

        lower = TYPECAST.make_node(TYPE.uinteger,
                    BINARY.make_node('MINUS', lower, base, lineno=lineno,
                                     func=lambda x, y: x - y), lineno)
        upper = TYPECAST.make_node(TYPE.uinteger,
                    BINARY.make_node('MINUS', upper, base, lineno=lineno,
                                     func=lambda x, y: x - y), lineno)
        if is_number(lower):
            lo = lower.value
            if lo < MIN_STRSLICE_IDX:
                lower.value = lo = MIN_STRSLICE_IDX

        if is_number(upper):
            up = upper.value
            if up > MAX_STRSLICE_IDX:
                upper.value = up = MAX_STRSLICE_IDX

        if is_number(lower, upper):
            if lo > up:
                return STRING('', lineno)

            if s.token == 'STRING':  # A constant string? Recalculate it now
                up += 1
                st = s.value.ljust(up)  # Procrustean filled (right)
                return STRING(st[lo:up], lineno)

            # a$(0 TO INF.) = a$
            if lo == MIN_STRSLICE_IDX and up == MAX_STRSLICE_IDX:
                return s

        return clss(s, lower, upper, lineno)
