#!/usr/bin/env python
# -*- coding: utf-8 -*-

from api.debug import __DEBUG__
from backend import Quad, MEMORY
from ast import NodeVisitor


class Translator(NodeVisitor):
    ''' ZX Spectrum translator
    '''
    def emit(self, *args):
        """ Convert the given args to a Quad (3 address code) instruction
        """
        quad = Quad(*args)
        __DEBUG__('EMMIT ' + str(quad))
        MEMORY.append(quad)

    def visit_NUMBER(self, node):
        __DEBUG__('NUMBER ' + str(node), 2)
        yield node.value

    def visit_END(self, node):
        arg = (yield node.children[0])
        __DEBUG__('END', 2)
        self.emit('end', arg)

