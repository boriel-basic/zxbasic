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


class String(Symbol):
    ''' Defines a string constant.
    '''
    def __init__(self, lineno, value):
        Symbol.__init__(self, value, 'STRING')
        self._type = 'string'
        self.lineno = lineno
        self.t = value

