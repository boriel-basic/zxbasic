#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

''' A class for an identifier parsed by the preprocessor.
It contains it's name, arguments and macro value.
'''

import copy
from exceptions import PreprocError
from macrocall import MacroCall


class ID(object):
    ''' This class represents an identifier. It's stores a string
    (the ID name and value by default).
    '''
    def __init__(self, id, args = None, value = None, lineno = None, fname = None):
        if fname is None:
            fname = CURRENT_FILE[-1]

        if value is None:
            value = [id]

        if not isinstance(value, list):
            value = [value]

        self.name = id 
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
        if self.value is None:
            return ''

        result = ''
        for token in self.value:
            if isinstance(token, MacroCall):
                if table.defined(token.id):
                    tmp = table[token.id]

                    if isinstance(tmp, ID):
                        token = copy.deepcopy(token)
                        token.id = tmp(table)

                result += token(table)
            else:
                if table.defined(token):
                    pass
                    #token = table[token]

                if isinstance(token, ID):
                    token = token(table)
                result += token

        return result

