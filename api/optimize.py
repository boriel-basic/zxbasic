#!/usr/bin/env python
# -*- coding: utf-8 -*-

from ast_ import NodeVisitor
from config import OPTIONS
import symbols


# TODO: Implement as a visitor with generators
class OptimizerVisitor(object):
    ''' Implements some optimizations
    '''
    def __init__(self):
        self.OLEVEL = OPTIONS.optimization.value

    def visit_LET(self, node):
        if self.OLEVEL > 1 and not node.children[0].accessed:
            return symbols.SENTENCE('NOP')

        self.visit_children(node)
        return node


    def visit_children(self, node):
        for i in range(len(node.children)):
            node.children[i] = self.visit(node.children[i])


    def visit(self, node):
        ''' Just visit the children
        '''
        if node is None:
            return None

        if node.token == 'LET':
            return self.visit_LET(node)

        if node.children:
            self.visit_children(node)

        return node