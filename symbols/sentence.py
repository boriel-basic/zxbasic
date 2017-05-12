#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .symbol_ import Symbol
from api.check import is_null


class SymbolSENTENCE(Symbol):
    ''' Defines a BASIC SENTENCE object. e.g. 'BORDER'.
    '''
    def __init__(self, keyword, *args):
        ''' keyword = 'BORDER', or 'PRINT'
        '''
        Symbol.__init__(self, *(x for x in args if not is_null(x)))
        self.keyword = keyword

    @property
    def args(self):
        return self.children

    @property
    def token(self):
        ''' Sentence takes it's token from the keyword not from it's name
        '''
        return self.keyword

