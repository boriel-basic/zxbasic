#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

''' Class for a Table of Defines.
Each identifier has a dictionary entry.
'''
import sys
import re

from _id import ID
from exceptions import PreprocError
from output import msg, warning, error
from output import CURRENT_FILE

RE_ID = re.compile(r'[a-zA-Z_][a-zA-Z0-9_]*')


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


    def define(self, _id, lineno, value = '', fname = None, args = None):
        ''' Defines the value of a macro.
        Issues a warning if the macro is already defined.
        '''
        if fname is None:
            if CURRENT_FILE:
                fname = CURRENT_FILE[-1]
            else: # If no files opened yet, use owns program fname
                fname = sys.argv[0]

        if self.defined(_id):
            i = self.table[_id]            
            warning(lineno, '"%s" redefined (previous definition at %s:%i)' % (i.name, i.fname, i.lineno))

        self.set(_id, lineno, value, fname, args)


    def set(self, _id, lineno, value = '', fname = None, args = None):
        ''' Like the above, but issues no warning on duplicate macro definitions.
        '''
        if fname is None:
            if CURRENT_FILE:
                fname = CURRENT_FILE[-1]
            else: # If no files opened yet, use owns program fname
                fname = sys.argv[0]

        self.table[_id] = ID(_id, args, value, lineno, fname)


    def undef(self, _id):
        if self.defined(_id):
            del self.table[_id]


    def defined(self, _id):
        ''' Returns if the given ID 
        is defined
        '''
        return _id.strip() in self.table.keys()


    def __getitem__(self, key):
        ''' Returns the ID instance given it's
        _id. If it does not exist, return the _id 
        itself.
        '''
        return self.table.get(key.strip(), key)


    def __setitem__(self, key, value):   
        ''' Assigns the value to the given table entry
        '''
        k = key.strip()
        if not RE_ID.match(k):
            raise PreprocError('"%s" must be an identifier' % key, None)

        self.table[key] = value
 
