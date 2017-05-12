#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .call import SymbolCALL


class SymbolFUNCCALL(SymbolCALL):
    ''' This class is the same as CALL, we just declare it to make
    a distinction. (e.g. the Token is gotten from the class name)

    A FunctionCall is a Call whose return value is going to be used
    later within an expression. Eg.

    CALL: f(x)
    FUNCCALL: a = 2 * f(x)

    This distinction is useful to discard values returned using the HEAP
    to avoid memory leaks.
    '''
    pass
