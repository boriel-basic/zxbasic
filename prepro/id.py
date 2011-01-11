#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

''' A class for an identifier parsed by the preprocessor.
It contains it's name, arguments and macro value.
'''

import copy
from exceptions import PreprocError


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
        self.__value = value
        self.lineno = lineno # line number at which de ID was defined
        self.fname = fname # file name in which the ID was defined
        self.args = args
        self.table = {} # A defines table. When the value function is called
                        # this table is reset. And every ID defined in the args body
                        # is "tied" to be later replaced with it's corresponding value

    @property
    def hasArgs(self):
        return self.args is not None

    
    def __str__(self):
        return self.name


    def value(self, arglist = None):
        ''' Evaluates the ID with the given arguments.
        Raises an error if wrong number of arguments passed.
        Allows recursive macros / ID calls.
        '''
        # If no args. passed and this ID needs it, return just the ID (default behaviour)
        if arglist is None and not self.hasArgs():
            return str(self)

        # If this ID does'n have args, then "evaluate" the args as (x,y,...)
        if not self.hasArgs():
            if arglist is None:
                return self.__value # This macro was correctly called

            # This macro is followed by an arg. list: (x, y, z). Append it.
            return self.__value + '(' + ', '.join(arglist) + ')'

        # At this point, the macro needs args, and they were provided. Check them.
        if len(arglist) != len(self.args):
            raise PreprocError('Macro "%s" expected %i params, got %i' % \
                (str(self), len(self.args), len(arglist)), self.lineno)

        # start params unification
        self.table = copy.deepcopy(ID_TABLE) # Resets table      

        # For every ID in given args, replace them with the given value
        for id in self.args:
            value = id
            

