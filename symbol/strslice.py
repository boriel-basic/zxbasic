#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol import Symbol
from number import Number
from typecast import TypeCast
from binary import Binary
from string import String
from gl import optemps


class StrSlice(Symbol):
    ''' Defines a string slice
    '''
    def __init__(self, lineno):
        Symbol.__init__(self, None, 'STRSLICE')
        self.lineno = lineno
        self._type = 'string'
        self.t = optemps.new_t()

    @classmethod
    def create(cls, lineno, s, lower, upper):
         ''' Creates a node for a string slice. S is the string expression Tree.
         Lower and upper are the bounds, if lower & upper are constants, and
         s is also constant, s, then a string constant is returned.
     
         If lower > upper, an empty string is returned.
         '''
         check_type(lineno, 'string', s)
         lo = up = None
         base = Number(lineno, OPTIONS.string_base.value)
     
         lower = TypeCast(lineno, 'u16', Binary.create(lineno, 'MINUS', lower, base, lambda x, y: x - y))
         upper = TypeCast(lineno, 'u16', Binary.create(lineno, 'MINUS', upper, base, lambda x, y: x - y))
     
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
                 return String(lineno, '')
     
             if s.token == 'STRING': # A constant string? Recalculate it now
                 up += 1
                 st = s.t.ljust(up) # Procrustean filled (right) /***/ This behaviour must be checked against Sinclair BASIC
                 return String(lineno, st[lo:up])
     
             # a$(0 TO INF.) = a$
             if lo == MIN_STRSLICE_IDX and up == MAX_STRSLICE_IDX:
                 return s
     
         return StrSlice(lineno, s, lower, upper)

