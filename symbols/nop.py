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


class SymbolNOP(Symbol):
    def __init__(self):
        Symbol.__init__(self)

    def __bool__(self):
        return False

    def __nonzero__(self):
        return self.__bool__()
