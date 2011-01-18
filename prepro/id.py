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
            value = id

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


    def __call__(self, table):
        if self.value is None:
            return ''

        result = ''
        for token in self.value:
            if isinstance(token, MacroCall):
                result += token(table)
            else:
                result += token

        return result
            
            
            

