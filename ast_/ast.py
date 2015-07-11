#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import types
from tree import Tree


# ----------------------------------------------------------------------
# Abstract Syntax Tree class
# ----------------------------------------------------------------------
class Ast(Tree):
    ''' Adds some methods for easier coding...
    '''
    pass

    '''
    def __get_value(self):
        return self.symbol.value

    def __set_value(self, value):
        self.symbol.value = value

    value = property(__get_value, __set_value)

    @property
    def token(self):
        return self.symbol.token


    @property
    def text(self):
        return self.symbol.text


    @property
    def lineno(self):
        return self.symbol.lineno # Only for some symbols, lookout!


    @property
    def _class(self):
        if hasattr(self.symbol, '_class'):
            return self.symbol._class

        return None


    def __get_t(self):
        return self.symbol.t

    def __set_t(self, value):
        self.symbol.t = value

    t = property(__get_t, __set_t)


    def __get_type(self):
        return self.symbol._type

    def __set_type(self, _type):
        self.symbol._type = _type

    _type = property(__get_type, __set_type)


    @property
    def size(self):
        return self.symbol.size
    '''

'''
class NodeVisitor(object):
    def visit(self, node):
        methname = 'visit_' + type(node).__name__
        meth = getattr(self, methname, None)
        if meth is None:
            meth = self.generic_visit

        return meth(node)

    def generic_visit(self, node):
        raise RuntimeError("No {} method".format('visit_' + type(node).__name__))
'''

class NodeVisitor(object):
    def visit(self, node):
        stack = [node]
        last_result = None

        while stack:
            try:
                last = stack[-1]
                if isinstance(last, types.GeneratorType):
                    stack.append(last.send(last_result))
                    last_result = None
                elif isinstance(last, Ast):
                    stack.append(self._visit(stack.pop()))
                else:
                    last_result = stack.pop()
            except StopIteration:
                stack.pop()

        return last_result

    def _visit(self, node):
        methname = 'visit_' + node.token
        meth = getattr(self, methname, None)
        if meth is None:
            meth = self.generic_visit
        return meth(node)

    @staticmethod
    def generic_visit(node):
        raise RuntimeError("No {}() method defined".format('visit_' + node.token))

