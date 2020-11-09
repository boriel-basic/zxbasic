#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License v3
# ----------------------------------------------------------------------

from .symbol_ import Symbol


class SymbolSENTENCE(Symbol):
    """ Defines a BASIC SENTENCE object. e.g. 'BORDER'.
    """
    def __init__(self, keyword, *args, **kwargs):
        """ keyword = 'BORDER', or 'PRINT'
        """
        assert not kwargs or 'lineno' in kwargs
        super(SymbolSENTENCE, self).__init__(*(x for x in args if x is not None))
        self.keyword = keyword
        self.lineno = kwargs.get('lineno', None)

    @property
    def args(self):
        return self.children

    @property
    def token(self):
        """ Sentence takes it's token from the keyword not from it's name
        """
        return self.keyword
