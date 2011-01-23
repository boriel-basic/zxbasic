#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

''' Class for a Table of Defines.
Each identifier has a dictionary entry.
'''
import sys

from id import ID
from output import msg, warning, error
from output import CURRENT_FILE


class DefinesTable(object):
    ''' A class which will store
    define labels, and its values.
    It will also susbtitute the current value
    of a label for the given value.
    '''
    def __init__(self):
        ''' Initializes table
        '''
        self.table = {}


    def define(self, id, lineno, value = '', fname = None, args = None):
        if fname is None:
            if CURRENT_FILE:
                fname = CURRENT_FILE[-1]
            else: # If no files opened yet, use owns program fname
                fname = sys.argv[0]

        if self.defined(id):
            i = self.table[id]            
            warning(lineno, '"%s" redefined (previous definition at %s:%i)' % (i.name, i.fname, i.lineno))

        self.table[id] = ID(id, args, value, lineno, fname)


    def undef(self, id):
        if self.defined(id):
            del self.table[id]


    def value(self, id, args = None):
        ''' Returns value of ID,
        recursively evalued
        '''
        if not self.defined(id):
            # If id not in table, its value is the id itself
            if args is None:
                return id

            # Evaluate X(... args). If X not defined, return X(... args)
            return id + '(' + ', '.join(args) + ')'

        return ID_TABLE[id].value(args)


    def defined(self, id):
        ''' Returns if the given ID 
        is defined
        '''
        return id in self.table.keys()


    def __getitem__(self, key):
        ''' Returns the ID instance given it's
        id.
        '''
        return self.table.get(key, None)


    def __setitem__(self, key, value):   
        ''' Assigns the value to the given table entry
        '''
        self.table[key] = value
 
