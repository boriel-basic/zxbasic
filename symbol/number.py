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


class SymbolNUMBER(Symbol):
    ''' Defines an NUMBER symbol.
    '''
    def __init__(self, value, _type = None, lineno = None):
        if lineno is None:
            raise ValueError # This should be changed to another exception

        Symbol.__init__(self, value, 'NUMBER')

        if int(value) == value:
            value = int(value)

        self.value = value

        if _type is not None:
            self._type = _type

        elif isinstance(value, float):
            if -32768.0 < value < 32767:
                self._type = 'fixed'
            else:
                self._type = 'float'

        elif isinstance(value, int):
            if 0 <= value < 256:
                self._type = 'u8'
            elif -128 <= value < 128:
                self._type = 'i8'
            elif 0 <= value < 65536:
                self._type = 'u16'
            elif -32768 <= value < 32768:
                self._type = 'i16'
            elif value < 0:
                self._type = 'i32'
            else:
                self._type = 'u32'

        self.t = value
        self.lineno = lineno


