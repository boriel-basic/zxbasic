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
from .tree import Tree


# ----------------------------------------------------------------------
# Abstract Syntax Tree class
# ----------------------------------------------------------------------
class Ast(Tree):
    """ Adds some methods for easier coding...
    """
    pass


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
