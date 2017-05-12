#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .symbol_ import Symbol


class SymbolPARAMLIST(Symbol):
    ''' Defines a list of parameters definitions in a function header
    '''
    def __init__(self, *params):
        Symbol.__init__(self, *params)
        self.size = 0

    def __getitem__(self, key):
        return self.children[key]

    def __setitem__(self, key, value):
        self.children[key] = value

    def __len__(self):
        return len(self.children)

    @classmethod
    def make_node(clss, node, *params):
        ''' This will return a node with a param_list
        (declared in a function declaration)
        Parameters:
            -node: A SymbolPARAMLIST instance or None
            -params: SymbolPARAMDECL insances
        '''
        if node is None:
            node = clss()

        if node.token != 'PARAMLIST':
            return clss.make_node(None, node, *params)

        for i in params:
            if i is not None:
                node.appendChild(i)

        return node

    def appendChild(self, param):
        ''' Overrides base class.
        '''
        Symbol.appendChild(self, param)
        if param.offset is None:
            param.offset = self.size
            self.size += param.size
