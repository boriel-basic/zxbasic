#!/usr/bin/env python
# -*- coding: utf-8 -*-

from api.debug import __DEBUG__
import api.errmsg
from api.config import OPTIONS
from backend import Quad, MEMORY
from ast import NodeVisitor


class TranslatorVisitor(NodeVisitor):
    ''' This visitor just adds the emit() method.
    '''
    def emit(self, *args):
        """ Convert the given args to a Quad (3 address code) instruction
        """
        quad = Quad(*args)
        __DEBUG__('EMMIT ' + str(quad))
        MEMORY.append(quad)


class Translator(TranslatorVisitor):
    ''' ZX Spectrum translator
    '''
    def visit_NUMBER(self, node):
        __DEBUG__('NUMBER ' + str(node), 2)
        yield node.value

    def visit_END(self, node):
        arg = (yield node.children[0])
        __DEBUG__('END', 2)
        self.emit('end', arg)


class VarTranslator(TranslatorVisitor):
    ''' Var Translator
    This translator emmits memory var space
    '''
    def visit_BLOCK(self, node):
        __DEBUG__('BLOCK', 2)
        for child in node.children:
            yield child

    def visit_LABEL(self, node):
        self.emit('label', node.mangled)
        for tmp in node.aliased_by:
            self.emit('label', tmp.mangled)

    def visit_VARDECL(self, node):
        entry = node.entry
        if not entry.accessed:
            api.errmsg.warning_not_used(entry.lineno, entry.name)
            if OPTIONS.optimization.value > 1:
                return
        if entry.addr is not None:
            self.emit('deflabel', entry.mangled, entry.addr)
            for entry in entry.aliased_by:
                self.emit('deflabel', entry._mangled, entry.addr)
        elif entry.alias is None:
            for alias in entry.aliased_by:
                self.emit('label', alias.mangled)
            if entry.default_value is None:
                self.emit('var', entry.mangled, entry.size)
            else:
                if isinstance(tree.symbol.entry.default_value, SymbolCONST) and \
                 tree.symbol.entry.default_value.token == 'CONST':
                    emmit('varx', tree.text, tree._type, [traverse_const(tree.symbol.entry.default_value)])
                else:
                    emmit('vard', tree.text, default_value(tree.symbol._type, tree.symbol.entry.default_value))

