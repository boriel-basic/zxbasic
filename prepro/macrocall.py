#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

import copy
from exceptions import PreprocError
from common import OPTIONS
from debug import __DEBUG__


class MacroCall(object):
    ''' A call to a macro, stored in an object.
    Every time the macro() is called, the macro returns
    it value.
    '''
    def __init__(self, lineno, table, _id, args = None):
        ''' Initializes the object with the ID table, the ID name and
        optionally, the passed args.
        '''
        self.table = table
        self._id = _id
        self.callargs = args
        self.lineno = lineno


    def eval(self, arg):
        ''' Evaluates a given argument. The token will be returned by default
        "as is", except if it's a macrocall. In such case it will be evaluated
        recursively.
        '''
        return str(arg()) # Evaluate the arg (could be a macrocall)


    def __call__(self, symbolTable = None):
        ''' Execute the macro call using LAZY evaluation
        '''
        if symbolTable is None:
            symbolTable = self.table

        __DEBUG__("Evaluating %s" % self._id)

        if not self.is_defined(symbolTable): # The macro is not defined => returned as is
            __DEBUG__("Macro %s not defined" % self._id)
            if self.callargs is None:
                return self._id

            return self._id + str(self.callargs)

        __DEBUG__("Macro %s defined" % self._id)
        # The macro is defined
        TABLE = copy.deepcopy(symbolTable)
        ID = TABLE[self._id] # Get the defined macro
        if ID.hasArgs and self.callargs is None: # If no args passed, returned as is
            return self._id

        if not ID.hasArgs: # The macro doesn't need args
            __DEBUG__('%s has no args defined' % self._id)
            if self.callargs is None: # If none passed, return the evaluated ID()
                tmp = ''.join(x(TABLE) if isinstance(x, MacroCall) else str(x) for x in ID.value)
                __DEBUG__("evaluation result: %s" % tmp)
                return tmp 

            # Otherwise, evaluate the ID and return it plus evaluated args
            return ID(TABLE) + '(' + ', '.join([x() for x in self.callargs]) + ')'

        # Now ensure both args and callargs have the same length
        if len(self.callargs) != len(ID.args):
            raise PreprocError('Macro "%s" expected %i params, got %i' % \
                (str(self._id), len(ID.args), len(self.callargs)), self.lineno)

        # Evaluate args, removing spaces
        args = [x().strip() for x in self.callargs]

        # Carry out unification
        for i in range(len(self.callargs)):
            TABLE.set(ID.args[i].name, self.lineno, args[i])

        tmp = ID(TABLE)
        if '\n' in tmp:
            tmp += '\n#line %i\n' % (self.lineno)
        
        return tmp

    
    def is_defined(self, symbolTable = None):
        ''' True if this macro has been defined
        '''
        if symbolTable is None:
            symbolTable = self.table

        return symbolTable.defined(self._id)
        

