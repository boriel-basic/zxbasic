#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol import Symbol



class ParamList(Symbol):
    ''' Defines a list of parameters definitions in a function header
    '''
    def __init__(self):
        Symbol.__init__(self, None, 'PARAMLIST')
        self.size = 0   # Will contain the sum of all the params size (byte params counts as 2 bytes)
        self.next = []


    @property
    def count(self):
        ''' Number of params
        '''
        return len(self.next)


    def add(self, param):
        ''' Adds another param to the parameter list
        '''
        if param is None:
            return

        self.next += [param]
        if param.offset is None:
            param.expr.offset = param.offset = self.size
            self.size += param.size
        

    @classmethod
    def create(cls, node, *args):
        ''' This will return a node with a param_list
        (declared in a function declaration)
        '''
        if node is None:
            node = cls()
    
        if node.token != 'PARAMLIST':
            return cls.create(None, node, *args)
    
        for param in args:
            node.add(param)
    
        return node
    
    
    
