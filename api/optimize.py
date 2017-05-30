#!/usr/bin/env python
# -*- coding: utf-8 -*-

from ast_ import NodeVisitor
from .config import OPTIONS
from api.errmsg import warning
import api.check as chk
from api.constants import TYPE
import api.global_ as gl
import symbols
import types
from api.debug import __DEBUG__
from api.errmsg import warning_not_used


class ToVisit(object):
    """ Used just to signal an object to be
    traversed.
    """
    def __init__(self, obj):
        self.obj = obj


# TODO: Implement as a visitor with generators
class OptimizerVisitor(NodeVisitor):
    """ Implements some optimizations
    """
    NOP = symbols.SENTENCE('NOP')  # Return this for "erased" nodes

    @staticmethod
    def TYPE(type_):
        """ Converts a backend type (from api.constants)
        to a SymbolTYPE object (taken from the SYMBOL_TABLE).
        If type_ is already a SymbolTYPE object, nothing
        is done.
        """
        if isinstance(type_, symbols.TYPE):
            return type_

        assert TYPE.is_valid(type_)
        return gl.SYMBOL_TABLE.basic_types[type_]

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

        __DEBUG__("Optimizer: Visiting node {}".format(str(node.obj)), 1)

        # print node.obj.token, node.obj.__repr__()
        methname = 'visit_' + node.obj.token
        meth = getattr(self, methname, None)
        if meth is None:
            meth = self.generic_visit

        return meth(node.obj)

    @property
    def O_LEVEL(self):
        return OPTIONS.optimization.value

    def visit_ADDRESS(self, node):
        if node.operand.token != 'ARRAYACCESS':
            if not chk.is_dynamic(node.operand):
                node = symbols.CONST(node, node.lineno)
        elif node.operand.offset is not None:  # A constant access. Calculate offset
            node = symbols.BINARY.make_node('PLUS',
                                            symbols.UNARY('ADDRESS', node.operand.entry, node.lineno,
                                                          type_=self.TYPE(gl.PTR_TYPE)),
                                            symbols.NUMBER(node.operand.offset, lineno=node.operand.lineno,
                                                           type_=self.TYPE(gl.PTR_TYPE)),
                                            lineno=node.lineno, func=lambda x, y: x + y
                                            )
        yield node

    def visit_BINARY(self, node):
        node = (yield self.generic_visit(node))  # This might convert consts to numbers if possible
        # Retry folding
        yield symbols.BINARY.make_node(node.operator, node.left, node.right, node.lineno, node.func, node.type_)

    def visit_BUILTIN(self, node):
        methodname = "visit_" + node.fname
        if hasattr(self, methodname):
            yield (yield getattr(self, methodname)(node))
        else:
            yield (yield self.generic_visit(node))

    def visit_CHR(self, node):
        node = (yield self.generic_visit(node))

        if all(chk.is_static(arg.value) for arg in node.operand):
            yield symbols.STRING(''.join(chr(x.value.value & 0xFF) for x in node.operand), node.lineno)
        else:
            yield node

    def visit_CONST(self, node):
        if chk.is_number(node.expr) or chk.is_const(node.expr):
            yield node.expr
        else:
            yield node

    def visit_FUNCCALL(self, node):
        node.args = (yield self.generic_visit(node.args))  # Avoid infinite recursion not visiting node.entry
        yield node

    def visit_CALL(self, node):
        node.args = (yield self.generic_visit(node.args))  # Avoid infinite recursion not visiting node.entry
        yield node

    def visit_FUNCDECL(self, node):
        if self.O_LEVEL > 1 and not node.entry.accessed:
            warning(node.entry.lineno, "Function '%s' is never called and has been ignored" % node.entry.name)
            yield self.NOP
        else:
            yield (yield self.generic_visit(node))

    def visit_LET(self, node):
        if self.O_LEVEL > 1 and not node.children[0].accessed:
            warning_not_used(node.children[0].lineno, node.children[0].name)
            yield self.NOP
        else:
            yield (yield self.generic_visit(node))

    def visit_RETURN(self, node):
        """ Visits only children[1], since children[0] points to
        the current function being returned from (if any), and
        might cause infinite recursion.
        """
        if len(node.children) == 2:
            node.children[1] = (yield ToVisit(node.children[1]))
        yield node

    def visit_UNARY(self, node):
        if node.operator == 'ADDRESS':
            yield (yield self.visit_ADDRESS(node))
        else:
            yield (yield self.generic_visit(node))

    @staticmethod
    def generic_visit(node):
        for i in range(len(node.children)):
            node.children[i] = (yield ToVisit(node.children[i]))

        yield node
