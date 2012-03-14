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
from number import Number
from typecast import TypeCast
from gl import optemps
from typecheck import is_number
from typecheck import is_string


class Unary(Symbol):
    ''' Defines an UNARY EXPRESSION e.g. (a + b)
        Only the operator (e.g. 'PLUS') is stored.
    '''
    def __init__(self, lineno, oper, a, _type = None):
        Symbol.__init__(self, oper, 'UNARY')
        self.operand = a
        self.t = optemps.new_t()
        self.lineno = lineno
        self.operator = oper
        self._type = _type


    @classmethod
    def create(cls, lineno, oper, a, func = None, _type = None, _class = Number):
        ''' Creates a node for a unary operation
            'func' parameter is a lambda function
            _type is the resulting type (by default, the
            same as the argument).
            For example, for LEN (str$), result type is 'u16'
            and arg type is 'string'
    
            _class = class of the returning node (NUMBER by default)
        '''
        if func is not None:
            if is_number(a): # Try constant-folding
                return _class(lineno, func(a.value))
            elif is_string(a):
                return _class(lineno, func(a.text))
    
        if _type is None:
            _type = a._type
    
        if oper == 'MINUS':
            if not is_signed(Type(lineno, _type)):
                _type = 'i' + _type[1:]
                a = TypeCast(lineno, _type, a)
        elif oper == 'NOT':
            _type = 'u8'
    
        return cls(lineno, oper, a, _type)


    @property
    def child(self):
        ''' Returns AST child node
        '''
        return [self.operand]
