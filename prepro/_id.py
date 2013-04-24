#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

''' A class for an identifier parsed by the preprocessor.
It contains it's name, arguments and macro value.
'''

import copy
from exceptions import PreprocError
from macrocall import MacroCall
from debug import __DEBUG__


class ID(object):
    ''' This class represents an identifier. It's stores a string
    (the ID name and value by default).
    '''
    def __init__(self, _id, args = None, value = None, lineno = None, fname = None):
        if fname is None:
            fname = CURRENT_FILE[-1]

        if value is None:
            value = [_id]

        if not isinstance(value, list):
            value = [value]

        self.name = _id 
        self.value = value
        self.lineno = lineno # line number at which de ID was defined
        self.fname = fname # file name in which the ID was defined
        self.args = args


    @property
    def hasArgs(self):
        return self.args is not None

    
    def __str__(self):
        return self.name


    def __dumptable(self, table):
        ''' Dumps table on screen
        for debuggin purposes
        '''
        for x in table.table.keys():
            print x, '\t<---', table[x], type(table[x]),
            if isinstance(table[x], ID):
                print table[x].value,
            print


    def __call__(self, table):
        __DEBUG__("evaluating id '%s'" % self.name)
        if self.value is None:
            __DEBUG__("undefined (null) value. BUG?")
            return ''

        result = ''
        for token in self.value:
            __DEBUG__("evaluating token '%s'" % str(token))
            if isinstance(token, MacroCall):
                __DEBUG__("token '%s'(%s) is a MacroCall" % (token._id, str(token)))
                if table.defined(token._id):
                    tmp = table[token._id]
                    __DEBUG__("'%s' is defined in the symbol table as '%s'" % (token._id, tmp.name))

                    if isinstance(tmp, ID) and not tmp.hasArgs:
                        __DEBUG__("'%s' is an ID" % tmp.name)
                        token = copy.deepcopy(token)
                        token._id = tmp(table) # ***
                        __DEBUG__("'%s' is the new id" % token._id)

                __DEBUG__("executing MacroCall '%s'" % token._id)
                tmp = token(table)
            else:
                if isinstance(token, ID):
                    __DEBUG__("token '%s' is an ID" % token._id)
                    token = token(table)

                tmp = token

            __DEBUG__("token got value '%s'" % tmp)
            result += tmp


        return result

