#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from call import SymbolCALL


class SymbolFUNCCALL(SymbolCALL):
    ''' This class is the same as CALL, we just declare it to make
    a distinction. (e.g. the Token is gotten from the class name)
    '''
    pass
