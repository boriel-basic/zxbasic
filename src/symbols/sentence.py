#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License v3
# ----------------------------------------------------------------------

from src.symbols.symbol_ import Symbol


class SymbolSENTENCE(Symbol):
    """Defines a BASIC SENTENCE object. e.g. 'BORDER'."""

    def __init__(self, lineno: int, filename: str, keyword: str, *args, is_sentinel=False):
        """Params:
        - keyword: BASIC sentence token like 'BORDER', 'PRINT', ...
        - sentinel: whether this sentence was automagically added by the compiler
            (i.e. a RETURN "" in a string function when the user does not return anything)
        """
        super().__init__(*(x for x in args if x is not None))
        self.keyword = keyword
        self.lineno = lineno
        self.filename = filename
        self.is_sentinel = is_sentinel

    @property
    def args(self):
        return self.children

    @property
    def token(self):
        """Sentence takes it's token from the keyword not from it's name"""
        return self.keyword
