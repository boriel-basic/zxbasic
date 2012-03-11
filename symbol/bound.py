#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from errmsg import syntax_error
from typecheck import is_number
from symbol import Symbol


class Bound(Symbol):
    ''' Defines an array bound
    '''
    def __init__(self, lineno, lower, upper):
        ''' Creates an array bound
        '''
        Symbol.__init__(self, None, 'BOUND')
        self.lower = lower
        self.upper = upper
        self.size = upper - lower + 1
        self.lineno = lineno

    
    @classmethod
    def create(cls, lineno, lower, upper):
        if not is_number(lower, upper):
            syntax_error(lineno, 'Array bounds must be constant')
            return None

        lower = int(lower.value)
        upper = int(upper.value)

        if lower < 0:
            syntax_error(lineno, 'Array bounds must be greater or equal to 0')
            return None
    
        if lower > upper:
            syntax_error(lineno, 'Lower array bound must be less or equal to upper one')
            return None
        
        return cls(lineno, lower, upper)

