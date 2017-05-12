#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .symbol_ import Symbol
from api.check import is_static
from api.errmsg import syntax_error


class SymbolBOUND(Symbol):
    ''' Defines an array bound.
        Eg.:
        DIM a(1 TO 10, 3 TO 5, 8) defines 3 bounds,
          1..10, 3..5, and 0..8
    '''
    def __init__(self, lower, upper):
        assert isinstance(lower, int)
        assert isinstance(upper, int)
        assert upper >= lower
        Symbol.__init__(self)
        self.lower = lower
        self.upper = upper

    @property
    def count(self):
        return self.upper - self.lower + 1

    @staticmethod
    def make_node(lower, upper, lineno):
        ''' Creates an array bound
        '''
        if not is_static(lower, upper):
            syntax_error(lineno, 'Array bounds must be constants')
            return None

        lower.value = int(lower.value)
        upper.value = int(upper.value)

        if lower.value < 0:
            syntax_error(lineno, 'Array bounds must be greater than 0')
            return None

        if lower.value > upper.value:
            syntax_error(lineno, 'Lower array bound must be less or equal to upper one')
            return None

        return SymbolBOUND(lower.value, upper.value)

    def __str__(self):
        if self.lower == 0:
            return '({})'.format(self.upper)

        return '({} TO {})'.format(self.lower, self.upper)

    def __repr__(self):
        return self.token + str(self)
