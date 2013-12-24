#!/usr/bin/env python
# -*- coding: utf-8 -*-

from api.debug import __DEBUG__
from api.errmsg import warning_not_used
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
                self.emit('deflabel', entry.mangled, entry.addr)
        elif entry.alias is None:
            for alias in entry.aliased_by:
                self.emit('label', alias.mangled)
            if entry.default_value is None:
                self.emit('var', entry.mangled, entry.size)
            else:
                if isinstance(entry.default_value, SymbolCONST) and \
                              entry.default_value.token == 'CONST':
                    emmit('varx', node.mangled, node.type_, [traverse_const(entry.default_value)])
                else:
                    emmit('vard', node.mangled, default_value(node.type_, entry.default_value))

    def visit_ARRAYDECL(self, node):
        entry = node.entry
        if not entry.accessed:
            warning_not_used(entry.lineno, entry.name)
            if OPTIONS.optimization.value > 1:
                return

        l = ['%04X' % (len(node.bounds) - 1)]  # Number of dimensions - 1

        for bound in node.bounds[1:]:
            l.append('%04X' % (bound.upper - bound.lower + 1))

        l.append('%02X' % node.type_.size)

        if entry.default_value is not None:
            l.extend(array_default_value(node.type_, entry.default_value))
        else:
            l.extend(['00'] * node.size)

        for alias in entry.aliased_by:
            offset = 1 + 2 * entry.count + alias.offset  # TODO: Generalize for multi-arch
            self.emit('deflabel', alias.mangled, '%s + %i' % (entry.mangled, offset))

        self.emit('vard', node.mangled, l)

        if entry.lbound_used:
            l = ['%04X' % len(node.bounds)] + \
                ['%04X' % bound.lower for bound in node.bounds]
            self.emit('vard', '__LBOUND__.' + entry.mangled, l)

        if entry.ubound_used:
            l = ['%04X' % len(node.bounds)] + \
                ['%04X' % bound.upper for bound in node.bounds]
            self.emit('vard', '__UBOUND__.' + entry.mangled, l)

