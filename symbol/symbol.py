#!/usr/bin/env python
# -*- coding: utf-8 -*-

from ast import Ast


class Symbol(Ast):
    ''' Symbol object to store everything related to
    a symbol.
    '''
    def __init__(self, *children):
        for child in children:
            self.appendChild(child)

    @property
    def token(self):
        ''' token = AST Symbol class name, removing the 'Symbol' prefix.
        '''
        return self.__class__.__name__[6:]  # e.g. 'ID', 'NUMBER', etc...

    def __str__(self):
        return self.token

    def __repr__(self):
        return str(self)
