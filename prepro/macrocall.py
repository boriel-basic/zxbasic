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
        __DEBUG__("evaluating '%s'" % self._id)
        if symbolTable is None:
            symbolTable = self.table

        if not self.is_defined(symbolTable): # The macro is not defined => returned as is
            __DEBUG__("macro '%s' not defined" % self._id)
            tmp = self._id
            if self.callargs is not None:
                tmp += str(self.callargs)

            __DEBUG__("evaluation result: %s" % tmp)
            return tmp

        # The macro is defined
        __DEBUG__("macro '%s' defined" % self._id)
        TABLE = copy.deepcopy(symbolTable)
        ID = TABLE[self._id] # Get the defined macro
        if ID.hasArgs and self.callargs is None: # If no args passed, returned as is
            return self._id

        if self.callargs: # has args. Evaluate them removing spaces
            __DEBUG__("'%s' has args defined" % self._id)
            __DEBUG__("evaluating %i arg(s) for '%s'" % (len(self.callargs), self._id ))
            args = [x(TABLE).strip() for x in self.callargs]
            __DEBUG__("macro call: %s%s" % (self._id, '(' + ', '.join(args) + ')'))

        if not ID.hasArgs: # The macro doesn't need args
            __DEBUG__("'%s' has no args defined" % self._id)
            tmp = ID(TABLE)
            if self.callargs is not None: # If args (even empty () list) passed calculate them
                tmp += '(' + ', '.join(args) + ')'

            __DEBUG__("evaluation result: %s" % tmp)
            return tmp 

        # Now ensure both args and callargs have the same length
        if len(self.callargs) != len(ID.args):
            raise PreprocError('Macro "%s" expected %i params, got %i' % \
                (str(self._id), len(ID.args), len(self.callargs)), self.lineno)

        # Carry out unification
        __DEBUG__('carrying out args unification')
        for i in range(len(self.callargs)):
            __DEBUG__("arg '%s' = '%s'" % (ID.args[i].name, args[i]))
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
        

