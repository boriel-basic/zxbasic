#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

import copy
from exceptions import PreprocError
from id import ID
from definestable import DefinesTable 


class MacroCall(object):
    ''' A call to a macro, stored in an object.
    Every time the macro() is called, the macro returns
    it value.
    '''
    def __init__(self, lineno, table, id, args = None):
        ''' Initializes the object with the ID table, the ID name and
        optionally, the passed args.
        '''
        self.table = table
        self.id = id
        self.callargs = args
        self.lineno


    def eval(self, token):
        ''' Evaluates a given token. The token will be returned by default
        "as is", except if it's a macrocall. In such case it will be called 
        '''
        if not isinstance(token, MacroCall):
            return token

        return token() # Evaluate the macrocall


    def __call__(self, symbolTable = None):
        ''' Execute the macro call using LAZY evaluation
        '''
        if symbolTable is None:
            symbolTable = self.table

        TABLE = copy.deepcopy(symbolTable)
        if not TABLE.defined(self.id): # The macro is not defined => returned as is
            if self.callargs is None:
                return self.id

            return self.id + '(' + ', '.join([self.eval(x) for x in self.callargs]) + ')'

        # The macro is defined
        ID = TABLE[self.id] # Get the defined macro
        if ID.hasArgs() and self.callargs is None: # If no args passed, returned as is
            return self.id

        # Now ensure both args and callargs have the same length
        if len(self.callargs) != len(ID.args):
            raise PreprocError('Macro "%s" expected %i params, got %i' % \
                (str(self), len(ID.args), len(self.callargs)), self.lineno)
                        
            

        if self.callargs is not None: # args needed
            if 

        
        
        
        

