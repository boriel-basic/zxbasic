#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

import copy
from .exceptions import PreprocError
from api.debug import __DEBUG__


class MacroCall(object):
    ''' A call to a macro, stored in an object.
    Every time the macro() is called, the macro returns
    it value.
    '''
    def __init__(self, lineno, table, id_, args=None):
        ''' Initializes the object with the ID table, the ID name and
        optionally, the passed args.
        '''
        self.table = table
        self.id_ = id_
        self.callargs = args
        self.lineno = lineno

    def eval(self, arg):
        ''' Evaluates a given argument. The token will be returned by default
        "as is", except if it's a macrocall. In such case it will be evaluated
        recursively.
        '''
        return str(arg())  # Evaluate the arg (could be a macrocall)

    def __call__(self, symbolTable=None):
        ''' Execute the macro call using LAZY evaluation
        '''
        __DEBUG__("evaluating '%s'" % self.id_, 2)
        if symbolTable is None:
            symbolTable = self.table

        # The macro is not defined => returned as is
        if not self.is_defined(symbolTable):
            __DEBUG__("macro '%s' not defined" % self.id_, 2)
            tmp = self.id_
            if self.callargs is not None:
                tmp += str(self.callargs)
            __DEBUG__("evaluation result: %s" % tmp, 2)
            return tmp

        # The macro is defined
        __DEBUG__("macro '%s' defined" % self.id_, 2)
        TABLE = copy.deepcopy(symbolTable)
        ID = TABLE[self.id_]  # Get the defined macro
        if ID.hasArgs and self.callargs is None:
            return self.id_  # If no args passed, returned as is

        if self.callargs:  # has args. Evaluate them removing spaces
            __DEBUG__("'%s' has args defined" % self.id_, 2)
            __DEBUG__("evaluating %i arg(s) for '%s'" %
                      (len(self.callargs), self.id_), 2)
            args = [x(TABLE).strip() for x in self.callargs]
            __DEBUG__("macro call: %s%s" %
                      (self.id_, '(' + ', '.join(args) + ')'), 2)

        if not ID.hasArgs:  # The macro doesn't need args
            __DEBUG__("'%s' has no args defined" % self.id_, 2)
            tmp = ID(TABLE)  # If no args passed, returned as is
            if self.callargs is not None:
                tmp += '(' + ', '.join(args) + ')'

            __DEBUG__("evaluation result: %s" % tmp, 2)
            return tmp

        # Now ensure both args and callargs have the same length
        if len(self.callargs) != len(ID.args):
            raise PreprocError('Macro "%s" expected %i params, got %i' %
                               (str(self.id_), len(ID.args),
                                len(self.callargs)), self.lineno)

        # Carry out unification
        __DEBUG__('carrying out args unification', 2)
        for i in range(len(self.callargs)):
            __DEBUG__("arg '%s' = '%s'" % (ID.args[i].name, args[i]), 2)
            TABLE.set(ID.args[i].name, self.lineno, args[i])

        tmp = ID(TABLE)
        if '\n' in tmp:
            tmp += '\n#line %i\n' % (self.lineno)

        return tmp

    def is_defined(self, symbolTable=None):
        ''' True if this macro has been defined
        '''
        if symbolTable is None:
            symbolTable = self.table

        return symbolTable.defined(self.id_)
