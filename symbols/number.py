#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol_ import Symbol


class SymbolNUMBER(Symbol):
    ''' Defines an NUMBER symbol.
    '''
    def __init__(self, value, type_=None, lineno=None):
        if lineno is None:
            raise ValueError  # This should be changed to another exception

        Symbol.__init__(self)

        if int(value) == value:
            value = int(value)
        else:
            value = float(value)

        self.value = value

        if type_ is not None:
            self.type_ = type_

        elif isinstance(value, float):
            if -32768.0 < value < 32767:
                self.type_ = 'fixed'
            else:
                self.type_ = 'float'

        elif isinstance(value, int):
            if 0 <= value < 256:
                self.type_ = 'u8'
            elif -128 <= value < 128:
                self.type_ = 'i8'
            elif 0 <= value < 65536:
                self.type_ = 'u16'
            elif -32768 <= value < 32768:
                self.type_ = 'i16'
            elif value < 0:
                self.type_ = 'i32'
            else:
                self.type_ = 'u32'

        self.lineno = lineno

    def __str__(self):
        return str(self.value)

    def __repr__(self):
        return "%s:%s" % (self.type_, str(self))
