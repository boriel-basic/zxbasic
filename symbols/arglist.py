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


class SymbolARGLIST(Symbol):
    ''' Defines a list of arguments in a function call or array access
    '''
    def __init__(self, *args):
        Symbol.__init__(self, *args)

    @property
    def args(self):
        return self.children

    @args.setter
    def args(self, value):
        for i in value:
            self.appendChild(i)

    def __getitem__(self, range):
        return self.args[range]

    def __setitem__(self, range, value):
        self.children[range] = value

    def __str__(self):
        return '(%s)' % (', '.join(str(x) for x in self.args))

    def __repr__(self):
        return str(self)

    @property
    def __len__(self):
        return len(self.args)

    @classmethod
    def make_node(clss, node, *args):
        ''' This will return a node with an argument_list.
        '''
        if node is None:
            node = clss()

        if node.token != 'ARGLIST':
            return clss.make_arg_list(None, node, *args)

        for arg in args:
            node.appendChild(arg)

        return node
