#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from ast import Ast


# ----------------------------------------------------------------------
# Abstract Syntax Tree class
# ----------------------------------------------------------------------
class Tree(Ast):
    ''' Adds some methods for easier coding...
    '''
    def __get_value(self):
        return self.symbol.value

    def __set_value(self, value):
        self.symbol.value = value

    value = property(__get_value, __set_value)


    @property
    def token(self):
        return self.symbol.token


    @property
    def text(self):
        return self.symbol.text


    @property
    def lineno(self):
        return self.symbol.lineno # Only for some symbols, lookout!


    @property
    def _class(self):
        if hasattr(self.symbol, '_class'):
            return self.symbol._class

        return None


    def __get_t(self):
        return self.symbol.t

    def __set_t(self, value):
        self.symbol.t = value

    t = property(__get_t, __set_t)


    def __get_type(self):
        return self.symbol._type

    def __set_type(self, _type):
        self.symbol._type = _type

    _type = property(__get_type, __set_type)


    @property
    def size(self):
        return self.symbol.size

