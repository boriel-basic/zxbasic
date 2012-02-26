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



class ArgList(Symbol):
    ''' Defines a list of arguments in a function call
    '''
    def __init__(self):
        Symbol.__init__(self, None, 'ARGLIST')
        self.next = []


    def __getitem__(self, range):
        return self.this.next[range]


    @property
    def count(self):
        ''' Number of args (params)
        '''
        return len(self.next)


    @classmethod
    def create(cls, node, *args):
        if node is None:
            node = cls()
    
        if node.token != 'ARGLIST':
            return cls.create(None, node, *args)
    
        for i in args:
            node.next.append(i)
    
        return node


    @property
    def child(self):
        ''' Return child nodes (AST)
        '''
        return self.next
        
        
