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



class BoundList(Symbol):
    ''' Defines a bound list for an array
    '''
    def __init__(self):
        Symbol.__init__(self, None, 'BOUNDLIST')
        self.__size = 0  # Total number of array cells
        self.bound = [] # Bound list

    @property
    def count(self):
        return len(self.bound)

    @property
    def size(self):
        return self.__size

    def add(self, node):
        if not self.__size:
            self.__size = 1

        self.bound += [node]
        self.__size *= node.size

    @property
    def child(self):
        return list(self.bound)

    @classmethod
    def create(cls, node, *args):
        ''' Creates an array BOUND LIST.
        '''
        if node is None:
            return cls.create(BoundList(), *args)
    
        if node.token != 'BOUNDLIST':
            return cls.create(None, node, *args)
    
        for i in args:
            node.add(i)
    
        return node
    
    
