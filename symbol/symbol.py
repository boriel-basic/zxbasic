#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

from ast import Ast
from debug import __DEBUG__

class Symbol(Ast):
    ''' Symbol object to store everything related to
    a symbol.
    '''
    def __init__(self, value, token):
        self.text = value
        self.token = token # e.g. 'ID', 'number', etc...

        try:
            self.value = float(value)
        except ValueError:
            self.value = None # Not a number value
        except TypeError:
            self.value = None # Not a number value


    @property
    def child(self):
        ''' Return child elements of the given node.
        By default it's empty (leave-node in the AST)
        '''
        if self.__class__.__name__ != 'Symbol':
            __DEBUG__('Using default symbol.child property for class ' + self.__class__.__name__)
        return []
