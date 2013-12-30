#!/usr/bin/env python
# -*- coding: utf-8 -*-

from api.constants import TYPE
from api.constants import SCOPE
from api.constants import CLASS

from api.debug import __DEBUG__
from api.errmsg import warning_not_used
from api.config import OPTIONS
from api.global_ import SYMBOL_TABLE
from api.global_ import optemps
from api.errors import InvalidLoopError
from api.errors import InvalidOperatorError

import backend
from backend import Quad, MEMORY
from ast_ import NodeVisitor
from backend.__float import _float

import symbols


class TranslatorVisitor(NodeVisitor):
    ''' This visitor just adds the emit() method.
    '''
    O_LEVEL = OPTIONS.optimization.value

    @staticmethod
    def TSUFFIX(type_):
        assert isinstance(type_, symbols.TYPE) or TYPE.is_valid(type_)

        _TSUFFIX = {TYPE.byte_: 'i8', TYPE.ubyte: 'u8',
                    TYPE.integer: 'i16', TYPE.uinteger: 'u16',
                    TYPE.long_: 'i32', TYPE.ulong: 'u32',
                    TYPE.fixed: 'f16', TYPE.float_: 'f',
                    TYPE.string: 'str'
                    }

        if isinstance(type_, symbols.TYPEREF):
            type_ = type_.final
            assert isinstance(type_, symbols.BASICTYPE)

        if isinstance(type_, symbols.BASICTYPE):
            return _TSUFFIX[type_.type_]

        return _TSUFFIX[type_]

    def emit(self, *args):
        """ Convert the given args to a Quad (3 address code) instruction
        """
        quad = Quad(*args)
        __DEBUG__('EMIT ' + str(quad))
        MEMORY.append(quad)

    # Generic Visitor methods
    def visit_BLOCK(self, node):
        __DEBUG__('BLOCK', 2)
        for child in node.children:
            yield child


class Translator(TranslatorVisitor):
    ''' ZX Spectrum translator
    '''
    def visit_NUMBER(self, node):
        __DEBUG__('NUMBER ' + str(node), 2)
        yield node.value


    def visit_STRING(self, node):
        __DEBUG__('STRING ' + str(node), 2)
        yield node.value


    def visit_END(self, node):
        arg = (yield node.children[0])
        __DEBUG__('END', 2)
        self.emit('end', arg)


    def visit_LET(self, node):
        assert isinstance(node.children[0], symbols.VAR)
        if self.O_LEVEL < 2 or node.children[0].accessed or node.children[1].token == 'CONST':
            yield node.children[1]
        __DEBUG__('LET', 2)
        self.emit_let_left_part(node)


    def visit_VAR(self, node):
        scope = node.scope

        if node.t == node.mangled and scope == SCOPE.global_:
            return

        if node.class_ in (CLASS.label, CLASS.const):
            return

        suffix = self.TSUFFIX(node.type_)
        p = '*' if node.byref else ''  # Indirection prefix
        alias = node.alias

        if scope == SCOPE.global_:
            self.emit('load' + suffix, node.name, node.mangled)
        elif scope == SCOPE.parameter:
            self.emit('pload' + suffix, node.name, p + str(node.offset))
        elif scope == SCOPE.local:
            offset = node.offset
            if alias is not None and alias.class_ == CLASS.array:
                offset -= 1 + 2 * alias.count

            self.emit('pload' + suffix, node.name, p + str(-offset))


    def visit_UNARY(self, node):
        yield node.operand

        uvisitor = UnaryVisitor()
        att = 'visit_{}'.format(node.operator)
        if hasattr(uvisitor, att):
            yield getattr(uvisitor, att)(node)
            return

        raise InvalidOperatorError(node.operator)


    def visit_BUILTIN(self, node):
        yield node.operand

        bvisitor = BuiltinVisitor()
        att = 'visit_{}'.format(node.fname)
        if hasattr(bvisitor, att):
            yield getattr(bvisitor, att)(node)
            return

        raise InvalidOperatorError(node.fname)


    def visit_BINARY(self, node):
        yield node.left
        yield node.right

        ins = {'PLUS': 'add', 'MINUS': 'sub'}.get(node.operator, node.operator.lower())
        s = self.TSUFFIX(node.type_)
        self.emit(ins + s, node.t, str(node.left.t), str(node.right.t))


    def visit_TYPECAST(self, node):
        yield node.operand
        assert node.operand.type_.is_basic
        assert node.type_.is_basic
        self.emit('cast', node.t, node.operand.type_.type_, node.type_.type_, node.operand.t)


    def emit_let_left_part(self, node, t=None):
        var = node.children[0]
        expr = node.children[1]
        p = '*' if var.byref else ''  # Indirection prefix

        if t is None:
            t = expr.t  # TODO: Check

        if self.O_LEVEL > 1 and not var.accessed:
            return

        if not var.type_.is_basic:
            raise NotImplementedError()

        if var.scope == SCOPE.global_:
            self.emit('store' + self.TSUFFIX(var.type_), var.mangled, t)
        elif var.scope == SCOPE.parameter:
            self.emit('pstore' + self.TSUFFIX(var.type_), p + str(var.offset), t)
        elif var.scope == SCOPE.local:
            if var.alias is not None and var.alias.class_ == CLASS.array:
                var.offset -= 1 + 2 * var.alias.count
            self.emit('pstore' + self.TSUFFIX(var.type_), p + str(-var.offset), t)


    @staticmethod
    def default_value(type_, value):
        ''' Returns a list of bytes (as hexadecimal 2 char string)
        '''
        assert isinstance(type_, symbols.TYPE)
        assert type_.is_basic

        if type_ == SYMBOL_TABLE.basic_types[TYPE.float_]:
            C, DE, HL = _float(value)
            C = C[:-1]  # Remove 'h' suffix
            if len(C) > 2:
                C = C[-2:]

            DE = DE[:-1]  # Remove 'h' suffix
            if len(DE) > 4:
                DE = DE[-4:]
            elif len(DE) < 3:
                DE = '00' + DE

            HL = HL[:-1]  # Remove 'h' suffix
            if len(HL) > 4:
                HL = HL[-4:]
            elif len(HL) < 3:
                HL = '00' + HL

            return [C, DE[-2:], DE[:-2], HL[-2:], HL[:-2]]

        if type_ == SYMBOL_TABLE.basic_types[TYPE.fixed]:
            value = 0xFFFFFFFF & int(value * 2 ** 16)

        # It's an integer type
        value = int(value)
        result = [value, value >> 8, value >> 16, value >> 24]
        result = ['%02X' % (value & 0xFF) for value in result]

        return result[:type_.size]


    @staticmethod
    def array_default_value(type_, values):
        ''' Returns a list of bytes (as hexadecimal 2 char string)
        which represents the array initial value.
        '''
        if not isinstance(values, list):
            return Translator.default_value(type_, values.value)

        l = []
        for row in values:
            l.extend(Translator.array_default_value(type_, row))

        return l



class VarTranslator(TranslatorVisitor):
    ''' Var Translator
    This translator emits memory var space
    '''
    def visit_LABEL(self, node):
        self.emit('label', node.mangled)
        for tmp in node.aliased_by:
            self.emit('label', tmp.mangled)


    def visit_VARDECL(self, node):
        entry = node.entry
        if not entry.accessed:
            warning_not_used(entry.lineno, entry.name)
            if self.O_LEVEL > 1:  # HINT: Unused vars not compiled
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
                if isinstance(entry.default_value, symbols.CONST) and \
                              entry.default_value.token == 'CONST':
                    self.emit('varx', node.mangled, node.type_, [traverse_const(entry.default_value)])
                else:
                    self.emit('vard', node.mangled, Translator.default_value(node.type_, entry.default_value))


    def visit_ARRAYDECL(self, node):
        entry = node.entry
        if not entry.accessed:
            warning_not_used(entry.lineno, entry.name)
            if self.O_LEVEL > 1:
                return

        l = ['%04X' % (len(node.bounds) - 1)]  # Number of dimensions - 1

        for bound in node.bounds[1:]:
            l.append('%04X' % (bound.upper - bound.lower + 1))

        l.append('%02X' % node.type_.size)

        if entry.default_value is not None:
            l.extend(Translator.array_default_value(node.type_, entry.default_value))
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


class UnaryVisitor(TranslatorVisitor):
    ''' UNARY sub-visitor. E.g. -a or bNot pi
    '''
    def visit_MINUS(self, node):
        self.emit('neg' + self.TSUFFIX(node.type_), node.t, node.operand.t)

    def visit_NOT(self, node):
        self.emit('not' + self.TSUFFIX(node.operand.type_), node.t, node.operand.t)

    def visit_BNOT(self, node):
        self.emit('bnot' + self.TSUFFIX(node.operand.type_), node.t, node.operand.t)


class BuiltinVisitor(TranslatorVisitor):
    ''' BUILTIN functions visitor. Eg. LEN(a$) or SIN(x)
    '''
    REQUIRES = backend.REQUIRES

    def visit_LEN(self, node):
        self.emit('lenstr', node.t, node.operand.t)

    def visit_SIN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_.type_), node.operand.t)
        self.emit('call', 'SIN', node.operand.size)
        self.REQUIRES.add('sin.asm')

    def visit_COS(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_.type_), node.operand.t)
        self.emit('call', 'COS', node.operand.size)
        self.REQUIRES.add('cos.asm')

    def visit_TAN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_.type_), node.operand.t)
        self.emit('call', 'TAN', node.operand.size)
        self.REQUIRES.add('tan.asm')

    def visit_ASN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_.type_), node.operand.t)
        self.emit('call', 'ASIN', node.operand.size)
        self.REQUIRES.add('asin.asm')

    def visit_ACS(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_.type_), node.operand.t)
        self.emit('call', 'ACOS', node.operand.size)
        self.REQUIRES.add('acos.asm')

    def visit_ATN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_.type_), node.operand.t)
        self.emit('call', 'ATAN', node.operand.size)
        self.REQUIRES.add('atan.asm')
