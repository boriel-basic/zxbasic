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
from string import String
from gl import optemps
from errmsg import syntax_error



class Binary(Symbol):
    ''' Defines a BINARY EXPRESSION e.g. (a + b)
        Only the operator (e.g. 'PLUS') is stored.
    '''
    def __init__(self, lineno, oper, a, b, func, _type = None):
        Symbol.__init__(self, oper, 'BINARY')
        self.left = None # Must be set by make_binary
        self.right = None
        self.t = optemps.new_t()
        self.lineno = lineno

   
    @classmethod
    def create(cls, lineno, oper, a, b, func, _type = None):
        ''' Creates a binary node for a binary operation
            'func' parameter is a lambda function
        '''
        if is_number(a, b): # Do constant folding
            return Number(func(a.value, b.value), _type = _type, lineno = lineno)
    
        # Check for constant non-nummeric operations
        c_type = common_type(a, b)
        if c_type: # there must be a common type for a and b
            if is_const(a, b) and is_type(c_type, a, b):
                return cls(lineno, oper, a, b, c_type)
        
            if is_const(a) and is_number(b) and is_type(c_type, a):
                return cls(lineno, oper, a, TypeCast(lineno, c_type, b))
        
            if is_const(b) and is_number(a) and is_type(c_type, b):
                return cls(lineno, oper, TypeCast(lineno, c_type, a), b)
    
        if oper in ('BNOT', 'BAND', 'BOR', 'BXOR',
                    'NOT', 'AND', 'OR', 'XOR',
                    'MINUS', 'MULT', 'DIV', 'SHL', 'SHR') and not is_numeric(a, b):
            syntax_error(lineno, 'Operator %s cannot be used with STRINGS' % oper)
            return None
    
        if is_string(a, b): # Are they STRING Constants?
            if oper == 'PLUS':
                return String(lineno, func(a.text, b.text))
            else:
                return Number(lineno, int(func(a.text, b.text)), _type = 'u8') # Convert to u8 (Boolean result)
    
        c_type = common_type(a, b)
    
        if oper in ('BNOT', 'BAND', 'BOR', 'BXOR'):
            if c_type in ('fixed', 'float'):
                c_type = 'i32'
    
        if oper not in ('SHR', 'SHL'):
            a = TypeCast(lineno, c_type, a)
            b = TypeCast(lineno, c_type, b)
    
        if _type is not None:
            rtype = _type
        elif oper in ('LT', 'GT', 'EQ', 'LE', 'GE', 'NE', 'AND', 'OR', 'XOR', 'NOT'):
            rtype = 'u8' # Boolean type
        else:
            rtype = c_type
    
        return cls(lineno, oper, a, b, rtype)
    
    
