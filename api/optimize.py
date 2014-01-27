#!/usr/bin/env python
# -*- coding: utf-8 -*-

from ast_ import NodeVisitor
from config import OPTIONS
from api.errmsg import warning
import api.check as chk
import symbols
import types


class ToVisit(object):
    ''' Used just to signal an object to be
    traversed.
    '''
    def __init__(self, obj):
        self.obj = obj


# TODO: Implement as a visitor with generators
class OptimizerVisitor(NodeVisitor):
    ''' Implements some optimizations
    '''
    NOP = symbols.SENTENCE('NOP')  # Return this for "erased" nodes

    def visit(self, node):
        if self.O_LEVEL < 0:  # Optimize only if O1 or above
            return node

        stack = [ToVisit(node)]
        last_result = None

        while stack:
            try:
                last = stack[-1]
                if isinstance(last, types.GeneratorType):
                    stack.append(last.send(last_result))
                    last_result = None
                elif isinstance(last, ToVisit):
                    stack.append(self._visit(stack.pop()))
                else:
                    last_result = stack.pop()
            except StopIteration:
                stack.pop()

        return last_result


    def _visit(self, node):
        if node.obj is None:
            return None

        #print node.obj.token, node.obj.__repr__()
        methname = 'visit_' + node.obj.token
        meth = getattr(self, methname, None)
        if meth is None:
            meth = self.generic_visit

        return meth(node.obj)


    @property
    def O_LEVEL(self):
        return OPTIONS.optimization.value


    def visit_ADDRESS(self, node):
        if not chk.is_dynamic(node.operand):
            node = symbols.CONST(node, node.lineno)

        yield node


    def visit_UNARY(self, node):
        if node.operator == 'ADDRESS':
            yield (yield self.visit_ADDRESS(node))
        else:
            yield (yield self.generic_visit(node))


    def visit_BINARY(self, node):
        node = (yield self.generic_visit(node))
        yield symbols.BINARY.make_node(node.operator, node.left, node.right, node.lineno)


    def visit_RETURN(self, node):
        ''' Visits only children[1], since children[0] points to
        the current function being returned from (if any), and
        might cause infinite recursion.
        '''
        if len(node.children) == 2:
            node.children[1] = (yield ToVisit(node.children[1]))
        yield node


    def visit_LET(self, node):
        if self.O_LEVEL > 1 and not node.children[0].accessed:
            yield self.NOP
        else:
            yield (yield self.generic_visit(node))


    def visit_FUNCDECL(self, node):
        if self.O_LEVEL > 0 and not node.entry.accessed:
            warning(node.entry.lineno, "Function '%s' is never called and has been ignored" % node.entry.name)
            yield self.NOP
        else:
            yield (yield self.generic_visit(node))


    @staticmethod
    def generic_visit(node):
        for i in range(len(node.children)):
            node.children[i] = (yield ToVisit(node.children[i]))

        yield node

