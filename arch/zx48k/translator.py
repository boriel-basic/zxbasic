#!/usr/bin/env python
# -*- coding: utf-8 -*-

__all__=['Translator',
         'VarTranslator',
         'FunctionTranslator']

from api.constants import TYPE
from api.constants import SCOPE
from api.constants import CLASS
from api.constants import CONVENTION

import api.errmsg
import api.global_ as gl

from api.debug import __DEBUG__
from api.errmsg import warning
from api.errmsg import syntax_error
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
from symbols.type_ import Type

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

    @staticmethod
    def emit(*args):
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
        __DEBUG__('NUMBER ' + str(node))
        yield node.value


    def visit_STRING(self, node):
        __DEBUG__('STRING ' + str(node))
        yield node.value


    def visit_END(self, node):
        arg = (yield node.children[0])
        __DEBUG__('END')
        self.emit('end', arg)


    def visit_LET(self, node):
        assert isinstance(node.children[0], symbols.VAR)
        if self.O_LEVEL < 2 or node.children[0].accessed or node.children[1].token == 'CONST':
            yield node.children[1]
        __DEBUG__('LET')
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
            self.emit('load' + suffix, node.t, node.mangled)
        elif scope == SCOPE.parameter:
            self.emit('pload' + suffix, node.t, p + str(node.offset))
        elif scope == SCOPE.local:
            offset = node.offset
            if alias is not None and alias.class_ == CLASS.array:
                offset -= 1 + 2 * alias.count

            self.emit('pload' + suffix, node.name, p + str(-offset))


    def visit_PARAMDECL(self, node):
        assert node.scope == SCOPE.parameter
        self.visit_VAR(node)


    def visit_UNARY(self, node):
        yield node.operand

        uvisitor = UnaryOpTranslator()
        att = 'visit_{}'.format(node.operator)
        if hasattr(uvisitor, att):
            yield getattr(uvisitor, att)(node)
            return

        raise InvalidOperatorError(node.operator)


    def visit_BUILTIN(self, node):
        yield node.operand

        bvisitor = BuiltinTranslator()
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


    def visit_FUNCDECL(self, node):
        if self.O_LEVEL > 0 and not node.entry.accessed:
            warning(node.entry.lineno, "Function '%s' is never called and has been ignored" % node.entry.name)
        else:
            # node.token = 'FUNCTION' # Delay emission of functions 'til the end
            gl.FUNCTIONS.append(node.entry)


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


    def visit_CALL(self, node):
        yield node.args  # arglist
        if node.entry.convention == CONVENTION.fastcall:
            if len(node.args) > 0:  # At least 1 parameter
                self.emit('fparam' + self.TSUFFIX(node.args[0].type_), node.args[0].t)

        self.emit('call', node.entry.mangled, 0)  # Procedure call. 0 = discard return


    def visit_ARGLIST(self, node):
        for i in range(len(node) - 1, -1, -1):  # visit in reverse order
            yield node[i]


    def visit_ARGUMENT(self, node):
        if not node.byref:
            if node.value.token == 'ID' and \
                node.type_ == Type.string and node.value.t[0] == '$':
                    node.value.t = optemps.new_t()

            yield node.value
            self.emit('param' + self.TSUFFIX(node.type_), node.value.t)
        else:
            scope = node.value.scope
            if node.t[0] == '_':
                t = optemps.new_t()
            else:
                t = node.t

            if scope == SCOPE.global_:
                self.emit('loadu16', t, '#' + node.mangled)
            elif scope == SCOPE.parameter:  # A function has used a parameter as an argument to another function call
                if not node.byref:  # It's like a local variable
                    self.emit('paddr', node.value.offset, t)
                else:
                    self.emit('ploadu16', t, str(node.value.offset))
            elif scope == SCOPE.local:
                self.emit('paddr', -node.value.offset, t)

            self.emit('paramu16', t)


    @staticmethod
    def default_value(type_, value):  # TODO: This function must be moved to api.xx
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
            api.errmsg.warning_not_used(entry.lineno, entry.name)
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
            api.errmsg.warning_not_used(entry.lineno, entry.name)
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


class UnaryOpTranslator(TranslatorVisitor):
    ''' UNARY sub-visitor. E.g. -a or bNot pi
    '''
    def visit_MINUS(self, node):
        self.emit('neg' + self.TSUFFIX(node.type_), node.t, node.operand.t)

    def visit_NOT(self, node):
        self.emit('not' + self.TSUFFIX(node.operand.type_), node.t, node.operand.t)

    def visit_BNOT(self, node):
        self.emit('bnot' + self.TSUFFIX(node.operand.type_), node.t, node.operand.t)


class BuiltinTranslator(TranslatorVisitor):
    ''' BUILTIN functions visitor. Eg. LEN(a$) or SIN(x)
    '''
    REQUIRES = backend.REQUIRES

    def visit_LEN(self, node):
        self.emit('lenstr', node.t, node.operand.t)

    def visit_SIN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'SIN', node.operand.size)
        self.REQUIRES.add('sin.asm')

    def visit_COS(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'COS', node.operand.size)
        self.REQUIRES.add('cos.asm')

    def visit_TAN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'TAN', node.operand.size)
        self.REQUIRES.add('tan.asm')

    def visit_ASN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'ASIN', node.operand.size)
        self.REQUIRES.add('asin.asm')

    def visit_ACS(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'ACOS', node.operand.size)
        self.REQUIRES.add('acos.asm')

    def visit_ATN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'ATAN', node.operand.size)
        self.REQUIRES.add('atan.asm')

    def visit_EXP(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'EXP', node.operand.size)
        self.REQUIRES.add('exp.asm')

    def visit_LN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'LN', node.operand.size)
        self.REQUIRES.add('logn.asm')

    def visit_SQR(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'SQRT', node.operand.size)
        self.REQUIRES.add('sqrt.asm')


class FunctionTranslator(Translator):
    REQUIRES = backend.REQUIRES

    def __init__(self, function_list):
        if function_list is None:
            function_list = []

        assert isinstance(function_list, list)
        for x in function_list:
            assert isinstance(x, symbols.FUNCTION)
        self.functions = function_list


    def start(self):
        for f in self.functions:
            __DEBUG__('Translating function ' + f.__repr__())
            self.visit(f)


    def visit_FUNCTION(self, node):
        self.emit('label', node.mangled)
        if node.convention == CONVENTION.fastcall:
            self.emit('enter', '__fastcall__')
        else:
            self.emit('enter', node.locals_size)

        for local_var in node.local_symbol_table.values():
            if not local_var.accessed:
                api.errmsg.warning_not_used(local_var.lineno, local_var.id)

            if local_var.class_ == CLASS.array:
                l = [x.size for x in local_var.bounds.children[1:]]  # TODO Check this
                l = [len(l)] + l  # Prepends len(l) (number of dimensions - 1)
                q = []
                for x in l:
                    q.append('%02X' % (x & 0xFF))
                    q.append('%02X' % (x >> 8))

                q.append('%02X' % local_var.size)
                if local_var.default_value is not None:
                    q.extend(self.array_default_value(local_var.type_, local_var.default_value))
                self.emit('lvard', local_var.offset, q)  # Initializes array bounds
            elif local_var.class_ == CLASS.const:
                continue
            else:
                if local_var.default_value is not None and local_var.default_value != 0:  # Local vars always defaults to 0, so if 0 we do nothing
                    if isinstance(local_var.default_value, symbols.CONST) and \
                                    local_var.default_value.token == 'CONST':
                        self.emit('lvarx', local_var.offset, local_var.type_,
                                  [self.traverse_const(local_var.default_value)])
                    else:
                        q = self.default_value(local_var.type_, local_var.default_value)
                        self.emit('lvard', local_var.offset, q)

        for i in node.body:
            yield i

        self.emit('label', '%s__leave' % node.mangled)

        # Now free any local string from memory.
        preserve_hl = False
        for local_var in node.local_symbol_table.values():
            if local_var.type_ == SYMBOL_TABLE.basic_types[TYPE.string]:  # Only if it's string we free it
                scope = local_var.scope
                if local_var.class_ != CLASS.array:  # Ok just free it
                    if scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref):
                        if not preserve_hl:
                            preserve_hl = True
                            self.emit('exchg')

                        offset = -local_var.offset if scope == SCOPE.parameter else local_var.offset
                        self.emit('fploadstr', local_var.t, offset)
                        self.emit('call', '__MEM_FREE', 0)
                        self.REQUIRES.add('free.asm')
                elif local_var.class_ == CLASS.const:
                    continue
                else:  # This is an array of strings, we must free it unless it's a by_ref array
                    if scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref):
                        if not preserve_hl:
                            preserve_hl = True
                            self.emit('exchg')

                        offset = -local_var.offset if scope == SCOPE.local else local_var.offset
                        elems = reduce(lambda x, y: x * y, [x.size for x in local_var.bounds.next])
                        self.emit('paramu16', elems)
                        self.emit('paddr', offset, local_var.t)
                        self.emit('fparamu16', local_var.t)
                        self.emit('call', '__ARRAY_FREE', 0)
                        self.REQUIRES.add('arrayfree.asm')

        if preserve_hl:
            self.emit('exchg')

        if node.convention == CONVENTION.fastcall:
            self.emit('leave', CONVENTION.to_string(node.convention))
        else:
            self.emit('leave', node.params.size)

        #raise InvalidOperatorError('a')


    def visit_FUNCDECL(self, node):
        raise InvalidOperatorError('FUNDECL')


    def visit_RETURN(self, node):
        if len(node.children) == 2: # Something to return?
            yield node.children[1]
            self.emit('ret' + self.TSUFFIX(node.children[1].type_), node.children[1].t,
                  '%s__leave' % node.children[0].mangled)
        elif len(node.children) == 1:
            self.emit('ret', '%s__leave' % node.children[0].mangled)
        else:
            self.emit('leave', '__fastcall__')
