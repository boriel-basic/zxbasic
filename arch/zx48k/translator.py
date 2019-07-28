#!/usr/bin/env python
# -*- coding: utf-8 -*-

from collections import namedtuple

from api.constants import TYPE
from api.constants import SCOPE
from api.constants import CLASS
from api.constants import KIND
from api.constants import CONVENTION

import api.errmsg
import api.global_ as gl
import api.check as check

from api.debug import __DEBUG__
from api.errmsg import syntax_error
from api.config import OPTIONS
from api.global_ import optemps
from api.errors import InvalidLoopError
from api.errors import InvalidOperatorError
from api.errors import InvalidBuiltinFunctionError

from . import backend
from .backend.__float import _float

import symbols
from symbols.type_ import Type
from .translatorvisitor import TranslatorVisitor

import arch.zx48k  # TODO: put this in global

__all__ = ['Translator',
           'VarTranslator',
           'FunctionTranslator']

JumpTable = namedtuple('JumpTable', ('label', 'addresses'))


class Translator(TranslatorVisitor):
    """ ZX Spectrum translator
    """
    def visit_NOP(self, node):
        pass  # nothing to do

    def visit_CLS(self, node):
        self.ic_call('CLS', 0)
        backend.REQUIRES.add('cls.asm')

    def visit_NUMBER(self, node):
        __DEBUG__('NUMBER ' + str(node))
        yield node.value

    def visit_STRING(self, node):
        __DEBUG__('STRING ' + str(node))
        node.t = '#' + self.add_string_label(node.value)
        yield node.t

    def visit_END(self, node):
        yield node.children[0]
        __DEBUG__('END')
        self.ic_end(node.children[0].t)

    def visit_ERROR(self, node):
        # Raises an error
        yield node.children[0]
        self.ic_fparam(TYPE.ubyte, node.children[0].t)
        self.ic_call('__ERROR', 0)
        backend.REQUIRES.add('error.asm')

    def visit_STOP(self, node):
        """ Returns to BASIC with an error code
        """
        yield node.children[0]
        self.ic_fparam(TYPE.ubyte, node.children[0].t)
        self.ic_call('__STOP', 0)
        self.ic_end(0)
        backend.REQUIRES.add('error.asm')

    def visit_LET(self, node):
        assert isinstance(node.children[0], symbols.VAR)
        if self.O_LEVEL < 2 or node.children[0].accessed or node.children[1].token == 'CONST':
            yield node.children[1]
        __DEBUG__('LET')
        self.emit_let_left_part(node)

    def visit_POKE(self, node):
        ch0 = node.children[0]
        ch1 = node.children[1]
        yield ch0
        yield ch1

        if ch0.token == 'VAR' and ch0.class_ != CLASS.const and ch0.scope == SCOPE.global_:
            self.ic_store(ch1.type_, '*' + str(ch0.t), ch1.t)
        else:
            self.ic_store(ch1.type_, str(ch0.t), ch1.t)

    def visit_RANDOMIZE(self, node):
        yield node.children[0]
        self.ic_fparam(node.children[0].type_, node.children[0].t)
        self.ic_call('RANDOMIZE', 0)
        backend.REQUIRES.add('random.asm')

    def visit_LABEL(self, node):
        self.ic_label(node.mangled)
        for tmp in node.aliased_by:
            self.ic_label(tmp.mangled)

    def visit_VAR(self, node):
        __DEBUG__('{}: VAR {}:{} Scope: {} Class: {}'.format(node.lineno, node.name, node.type_,
                                                             SCOPE.to_string(node.scope), CLASS.to_string(node.class_)))
        scope = node.scope

        if node.t == node.mangled and scope == SCOPE.global_:
            return

        if node.class_ in (CLASS.label, CLASS.const):
            return

        p = '*' if node.byref else ''  # Indirection prefix

        if scope == SCOPE.parameter:
            self.ic_pload(node.type_, node.t, p + str(node.offset))
        elif scope == SCOPE.local:
            offset = node.offset
            if node.alias is not None and node.alias.class_ == CLASS.array:
                offset -= 1 + 2 * node.alias.count  # TODO this is actually NOT implemented

            self.ic_pload(node.type_, node.t, p + str(-offset))

    def visit_CONST(self, node):
        node.t = '#' + (self.traverse_const(node) or '')
        yield node.t

    def visit_VARARRAY(self, node):
        pass

    def visit_PARAMDECL(self, node):
        assert node.scope == SCOPE.parameter
        self.visit_VAR(node)

    def visit_UNARY(self, node):
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

        raise InvalidBuiltinFunctionError(node.fname)

    def visit_BINARY(self, node):
        yield node.left
        yield node.right

        ins = {'PLUS': 'add', 'MINUS': 'sub'}.get(node.operator, node.operator.lower())
        s = self.TSUFFIX(node.left.type_)  # Operands type
        self.emit(ins + s, node.t, str(node.left.t), str(node.right.t))

    def visit_TYPECAST(self, node):
        yield node.operand
        assert node.operand.type_.is_basic
        assert node.type_.is_basic
        self.ic_cast(node.t, node.operand.type_, node.type_, node.operand.t)

    def visit_FUNCDECL(self, node):
        # Delay emission of functions until the end of the main code
        gl.FUNCTIONS.append(node.entry)

    def visit_CALL(self, node):
        yield node.args  # arglist
        if node.entry.convention == CONVENTION.fastcall:
            if len(node.args) > 0:  # At least 1 parameter
                self.emit('fparam' + self.TSUFFIX(node.args[0].type_), optemps.new_t())

        self.emit('call', node.entry.mangled, 0)  # Procedure call. 0 = discard return
        if node.entry.kind == KIND.function and node.entry.type_ == self.TYPE(TYPE.string):
            self.emit('call', '__MEM_FREE', 0)  # Discard string return value if the called function has any
            backend.REQUIRES.add('free.asm')

    def visit_ARGLIST(self, node):
        for i in range(len(node) - 1, -1, -1):  # visit in reverse order
            yield node[i]

            if isinstance(node.parent, symbols.ARRAYACCESS) and OPTIONS.arrayCheck.value:
                upper = node.parent.entry.bounds[i].upper
                lower = node.parent.entry.bounds[i].lower
                self.emit('paramu16', upper - lower)

    def visit_ARGUMENT(self, node):
        if not node.byref:
            suffix = self.TSUFFIX(node.type_)
            if node.value.token in ('VAR', 'PARAMDECL') and \
                    node.type_.is_dynamic and node.value.t[0] == '$':
                # Duplicate it in the heap
                assert (node.value.scope in (SCOPE.local, SCOPE.parameter))
                if node.value.scope == SCOPE.local:
                    self.emit('pload' + suffix, node.t, str(-node.value.offset))
                else:  # PARAMETER
                    self.emit('pload' + suffix, node.t, str(node.value.offset))
            else:
                yield node.value
            self.emit('param' + suffix, node.t)
        else:
            scope = node.value.scope
            if node.t[0] == '_':
                t = optemps.new_t()
            else:
                t = node.t

            if scope == SCOPE.global_:
                self.emit('loadu16', t, '#' + node.mangled)
            elif scope == SCOPE.parameter:  # A function has used a parameter as an argument to another function call
                if not node.value.byref:  # It's like a local variable
                    self.emit('paddr', node.value.offset, t)
                else:
                    self.emit('ploadu16', t, str(node.value.offset))
            elif scope == SCOPE.local:
                self.emit('paddr', -node.value.offset, t)

            self.emit('paramu16', t)

    def visit_ARRAYLOAD(self, node):
        scope = node.entry.scope

        if node.offset is None:
            yield node.args

            if scope == SCOPE.global_:
                self.emit('aload' + self.TSUFFIX(node.type_), node.entry.t, node.entry.mangled)
            elif scope == SCOPE.parameter:
                self.emit('paload' + self.TSUFFIX(node.type_), node.t, node.entry.offset)
            elif scope == SCOPE.local:
                self.emit('paload' + self.TSUFFIX(node.type_), node.t, -node.entry.offset)
        else:
            offset = node.offset
            if scope == SCOPE.global_:
                self.emit('load' + self.TSUFFIX(node.type_), node.entry.t, '%s + %i' % (node.entry.t, offset))
            elif scope == SCOPE.parameter:
                self.emit('pload' + self.TSUFFIX(node.type_), node.t, node.entry.offset - offset)
            elif scope == SCOPE.local:
                t1 = optemps.new_t()
                t2 = optemps.new_t()
                t3 = optemps.new_t()
                self.emit('pload' + self.TSUFFIX(gl.PTR_TYPE), t1,
                          -(node.entry.offset - self.TYPE(gl.PTR_TYPE).size))
                self.emit('add' + self.TSUFFIX(gl.PTR_TYPE), t2, t1, node.offset)
                self.emit('load' + self.TSUFFIX(node.type_), t3, '*$%s' % t2)

    def visit_ARRAYCOPY(self, node):
        tr = node.children[0]
        scope = tr.scope
        if scope == SCOPE.global_:
            t1 = "#%s" % tr.data_label
        elif scope == SCOPE.parameter:
            t1 = optemps.new_t()
            self.emit('pload%s' % self.TSUFFIX(gl.PTR_TYPE), t1, '%i' % (tr.offset - self.TYPE(gl.PTR_TYPE).size))
        elif scope == SCOPE.local:
            t1 = optemps.new_t()
            self.emit('pload%s' % self.TSUFFIX(gl.PTR_TYPE), t1, '%i' % -(tr.offset - self.TYPE(gl.PTR_TYPE).size))

        tr = node.children[1]
        scope = tr.scope
        if scope == SCOPE.global_:
            t2 = "#%s" % tr.data_label
        elif scope == SCOPE.parameter:
            t2 = optemps.new_t()
            self.emit('pload%s' % self.TSUFFIX(gl.PTR_TYPE), t2, '%i' % (tr.offset - self.TYPE(gl.PTR_TYPE).size))
        elif scope == SCOPE.local:
            t2 = optemps.new_t()
            self.emit('pload%s' % self.TSUFFIX(gl.PTR_TYPE), t2, '%i' % -(tr.offset - self.TYPE(gl.PTR_TYPE).size))

        t = optemps.new_t()
        if tr.type_ != Type.string:
            self.emit('load%s' % self.TSUFFIX(gl.PTR_TYPE), t, '%i' % tr.size)
            self.emit('memcopy', t1, t2, t)
        else:
            self.emit('load%s' % self.TSUFFIX(gl.PTR_TYPE), '%i' % tr.count)
            self.emit('call', 'STR_ARRAYCOPY', 0)
            backend.REQUIRES.add('strarraycpy.asm')

    def visit_LETARRAY(self, node):
        if self.O_LEVEL > 1 and not node.children[0].entry.accessed:
            return

        yield node.children[1]  # Right expression
        arr = node.children[0]  # Array access
        scope = arr.scope
        suf = self.TSUFFIX(arr.type_)

        if arr.offset is None:
            yield arr

            if scope == SCOPE.global_:
                self.emit('astore' + suf, arr.entry.mangled, node.children[1].t)
            elif scope == SCOPE.parameter:
                self.emit('pastore' + suf, arr.entry.offset, node.children[1].t)
            elif scope == SCOPE.local:
                self.emit('pastore' + suf, -arr.entry.offset, node.children[1].t)
        else:
            name = arr.entry.data_label
            if scope == SCOPE.global_:
                self.emit('store' + suf, '%s + %i' % (name, arr.offset), node.children[1].t)
            elif scope == SCOPE.parameter:
                self.emit('pstore' + suf, arr.entry.offset - arr.offset, node.children[1].t)
            elif scope == SCOPE.local:
                self.emit('pstore' + suf, -(arr.entry.offset - arr.offset), node.children[1].t)

    def visit_LETSUBSTR(self, node):
        yield node.children[3]
        self.emit('paramstr', node.children[3].t)

        if node.children[3].token != 'STRING' and (node.children[3].token != 'VAR' or
                                                   node.children[3].mangled[0] != '_'):
            self.emit('paramu8', 1)  # If the argument is not a variable, it must be freed
        else:
            self.emit('paramu8', 0)

        yield node.children[1]
        self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), node.children[1].t)
        yield node.children[2]
        self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), node.children[2].t)

        self.emit('fparam' + self.TSUFFIX(gl.PTR_TYPE), node.children[0].t)
        self.emit('call', '__LETSUBSTR', 0)
        backend.REQUIRES.add('letsubstr.asm')

    def visit_LETARRAYSUBSTR(self, node):
        if self.O_LEVEL > 1 and not node.children[0].entry.accessed:
            return

        expr = node.children[3]  # right expression
        yield expr
        self.emit('paramstr', expr.t)

        if expr.token != 'STRING' and (expr.token != 'VAR' or expr.mangled[0] != '_'):
            self.emit('paramu8', 1)  # If the argument is not a variable, it must be freed
        else:
            self.emit('paramu8', 0)

        yield node.children[1]
        self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), node.children[1].t)
        yield node.children[2]
        self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), node.children[2].t)

        node_ = node.children[0]
        scope = node_.scope
        entry = node_.entry
        suffix = self.TSUFFIX(gl.PTR_TYPE)

        # Address of an array element.
        if node_.offset is None:
            yield node_
            if scope == SCOPE.global_:
                self.emit('aload' + suffix, node_.t, entry.mangled)
            elif scope == 'parameter':
                self.emit('paloadstr' + suffix, node_.t, entry.offset)
            elif scope == 'local':
                self.emit('paloadstr' + suffix, node_.t, -entry.offset)
        else:
            offset = node_.offset
            if scope == SCOPE.global_:
                self.emit('load' + suffix, entry.t, '%s + %i' % (entry.mangled, offset))
            elif scope == SCOPE.parameter:
                self.emit('pload' + suffix, node_.t, entry.offset - offset)
            elif scope == SCOPE.local:
                self.emit('pload' + suffix, node_.t, -(entry.offset - offset))

        self.emit('fparam' + suffix, node.children[0].t)
        self.emit('call', '__LETSUBSTR', 0)
        backend.REQUIRES.add('letsubstr.asm')

    def visit_ARRAYACCESS(self, node):
        yield node.arglist

    def visit_STRSLICE(self, node):
        yield node.string
        if node.string.token == 'STRING' or \
                                node.string.token == 'VAR' and node.string.scope == SCOPE.global_:
            self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), node.string.t)

        # Now emit the slicing indexes
        yield node.lower
        self.emit('param' + self.TSUFFIX(node.lower.type_), node.lower.t)

        yield node.upper
        self.emit('param' + self.TSUFFIX(node.upper.type_), node.upper.t)

        if (node.string.token in ('VAR', 'PARAMDECL') and
                node.string.mangled[0] == '_' or node.string.token == 'STRING'):
            self.emit('fparamu8', 0)
        else:
            self.emit('fparamu8', 1)  # If the argument is not a variable, it must be freed

        self.emit('call', '__STRSLICE', self.TYPE(gl.PTR_TYPE).size)
        backend.REQUIRES.add('strslice.asm')

    def visit_FUNCCALL(self, node):
        yield node.args

        if node.entry.convention == CONVENTION.fastcall:
            if len(node.args) > 0:  # At least 1
                self.emit('fparam' + self.TSUFFIX(node.args[0].type_), optemps.new_t())

        self.emit('call', node.entry.mangled, node.entry.size)

    def visit_RESTORE(self, node):
        if not gl.DATA_IS_USED:
            return  # If no READ is used, ignore all DATA related statements
        lbl = gl.DATA_LABELS[node.args[0].name]
        self.emit('fparam' + self.TSUFFIX(node.args[0].type_), '#' + lbl)
        self.emit('call', '__RESTORE', 0)
        backend.REQUIRES.add('read_restore.asm')

    def visit_READ(self, node):
        self.emit('fparamu8', '#' + str(self.DATA_TYPES[self.TSUFFIX(node.args[0].type_)]))
        self.emit('call', '__READ', node.args[0].type_.size)

        if isinstance(node.args[0], symbols.ARRAYACCESS):
            arr = node.args[0]
            t = api.global_.optemps.new_t()
            scope = arr.scope
            suf = self.TSUFFIX(arr.type_)

            if arr.offset is None:
                yield arr

                if scope == SCOPE.global_:
                    self.emit('astore' + suf, arr.entry.mangled, t)
                elif scope == SCOPE.parameter:
                    self.emit('pastore' + suf, arr.entry.offset, t)
                elif scope == SCOPE.local:
                    self.emit('pastore' + suf, -arr.entry.offset, t)
            else:
                name = arr.entry.mangled
                if scope == SCOPE.global_:
                    self.emit('store' + suf, '%s + %i' % (name, arr.offset), t)
                elif scope == SCOPE.parameter:
                    self.emit('pstore' + suf, arr.entry.offset - arr.offset, t)
                elif scope == SCOPE.local:
                    self.emit('pstore' + suf, -(arr.entry.offset - arr.offset), t)

        else:
            self.emit_var_assign(node.args[0], t=api.global_.optemps.new_t())
        backend.REQUIRES.add('read_restore.asm')

    # region Control Flow Sentences
    # -----------------------------------------------------------------------------------------------------
    # Control Flow Compound sentences FOR, IF, WHILE, DO UNTIL...
    # -----------------------------------------------------------------------------------------------------
    def visit_DO_LOOP(self, node):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        self.LOOPS.append(('DO', end_loop, loop_label))  # Saves which labels to jump upon EXIT or CONTINUE

        self.emit('label', loop_label)
        if node.children:
            yield node.children[0]

        self.emit('jump', loop_label)
        self.emit('label', end_loop)
        self.LOOPS.pop()
        # del loop_label, end_loop

    def visit_DO_UNTIL(self, node):
        return self.visit_UNTIL_DO(node)

    def visit_DO_WHILE(self, node):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        continue_loop = backend.tmp_label()

        if node.token == 'WHILE_DO':
            self.emit('jump', continue_loop)

        self.emit('label', loop_label)
        self.LOOPS.append(('DO', end_loop, continue_loop))  # Saves which labels to jump upon EXIT or CONTINUE

        if len(node.children) > 1:
            yield node.children[1]

        self.emit('label', continue_loop)
        yield node.children[0]
        self.emit('jnzero' + self.TSUFFIX(node.children[0].type_), node.children[0].t, loop_label)
        self.emit('label', end_loop)
        self.LOOPS.pop()
        # del loop_label, end_loop, continue_loop

    def visit_EXIT_DO(self, node):
        self.emit('jump', self.loop_exit_label('DO'))

    def visit_EXIT_WHILE(self, node):
        self.emit('jump', self.loop_exit_label('WHILE'))

    def visit_EXIT_FOR(self, node):
        self.emit('jump', self.loop_exit_label('FOR'))

    def visit_CONTINUE_DO(self, node):
        self.emit('jump', self.loop_cont_label('DO'))

    def visit_CONTINUE_WHILE(self, node):
        self.emit('jump', self.loop_cont_label('WHILE'))

    def visit_CONTINUE_FOR(self, node):
        self.emit('jump', self.loop_cont_label('FOR'))

    def visit_FOR(self, node):
        loop_label_start = backend.tmp_label()
        loop_label_gt = backend.tmp_label()
        end_loop = backend.tmp_label()
        loop_body = backend.tmp_label()
        loop_continue = backend.tmp_label()
        suffix = self.TSUFFIX(node.children[0].type_)

        self.LOOPS.append(('FOR', end_loop, loop_continue))  # Saves which label to jump upon EXIT FOR and CONTINUE FOR

        yield node.children[1]  # Gets starting value (lower limit)
        self.emit_let_left_part(node)  # Stores it in the iterator variable
        self.emit('jump', loop_label_start)

        # FOR body statements
        self.emit('label', loop_body)
        yield node.children[4]

        # Jump here to continue next iteration
        self.emit('label', loop_continue)

        # VAR = VAR + STEP
        yield node.children[0]  # Iterator Var
        yield node.children[3]  # Step
        t = optemps.new_t()
        self.emit('add' + suffix, t, node.children[0].t, node.children[3].t)
        self.emit_let_left_part(node, t)

        # Loop starts here
        self.emit('label', loop_label_start)

        # Emmit condition
        if check.is_number(node.children[3]) or check.is_unsigned(node.children[3].type_):
            direct = True
        else:
            direct = False
            yield node.children[3]  # Step
            self.emit('jgezero' + suffix, node.children[3].t, loop_label_gt)

        if not direct or node.children[3].value < 0:  # Here for negative steps
            # Compares if var < limit2
            yield node.children[0]  # Value of var
            yield node.children[2]  # Value of limit2
            self.emit('lt' + suffix, node.t, node.children[0].t, node.children[2].t)
            self.emit('jzerou8', node.t, loop_body)

        if not direct:
            self.emit('jump', end_loop)
            self.emit('label', loop_label_gt)

        if not direct or node.children[3].value >= 0:  # Here for positive steps
            # Compares if var > limit2
            yield node.children[0]  # Value of var
            yield node.children[2]  # Value of limit2
            self.emit('gt' + suffix, node.t, node.children[0].t, node.children[2].t)
            self.emit('jzerou8', node.t, loop_body)

        self.emit('label', end_loop)
        self.LOOPS.pop()

    def visit_GOTO(self, node):
        self.emit('jump', node.children[0].mangled)

    def visit_GOSUB(self, node):
        self.emit('call', node.children[0].mangled, 0)

    def visit_ON_GOTO(self, node):
        table_label = backend.tmp_label()
        self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), '#' + table_label)
        yield node.children[0]
        self.emit('fparam' + self.TSUFFIX(node.children[0].type_), node.children[0].t)
        self.emit('call', '__ON_GOTO', 0)
        self.JUMP_TABLES.append(JumpTable(table_label, node.children[1:]))
        backend.REQUIRES.add('ongoto.asm')

    def visit_ON_GOSUB(self, node):
        table_label = backend.tmp_label()
        self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), '#' + table_label)
        yield node.children[0]
        self.emit('fparam' + self.TSUFFIX(node.children[0].type_), node.children[0].t)
        self.emit('call', '__ON_GOSUB', 0)
        self.JUMP_TABLES.append(JumpTable(table_label, node.children[1:]))
        backend.REQUIRES.add('ongoto.asm')

    def visit_CHKBREAK(self, node):
        if self.PREV_TOKEN != node.token:
            self.emit('inline', 'push hl', node.children[0].t)
            self.emit('fparam' + self.TSUFFIX(gl.PTR_TYPE), node.children[0].t)
            self.emit('call', 'CHECK_BREAK', 0)
            backend.REQUIRES.add('break.asm')

    def visit_IF(self, node):
        assert 1 < len(node.children) < 4, 'IF nodes: %i' % len(node.children)
        yield node.children[0]
        if_label_else = backend.tmp_label()
        if_label_endif = backend.tmp_label()

        if len(node.children) == 3:  # Has else?
            self.emit('jzero' + self.TSUFFIX(node.children[0].type_), node.children[0].t, if_label_else)
        else:
            self.emit('jzero' + self.TSUFFIX(node.children[0].type_), node.children[0].t, if_label_endif)

        yield node.children[1]  # THEN...

        if len(node.children) == 3:  # Has else?
            self.emit('jump', if_label_endif)
            self.emit('label', if_label_else)
            yield node.children[2]

        self.emit('label', if_label_endif)

    def visit_RETURN(self, node):
        if len(node.children) == 2:  # Something to return?
            yield node.children[1]
            self.emit('ret' + self.TSUFFIX(node.children[1].type_), node.children[1].t,
                      '%s__leave' % node.children[0].mangled)
        elif len(node.children) == 1:
            self.emit('ret', '%s__leave' % node.children[0].mangled)
        else:
            self.emit('leave', '__fastcall__')

    def visit_UNTIL_DO(self, node):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        continue_loop = backend.tmp_label()

        if node.token == 'UNTIL_DO':
            self.emit('jump', continue_loop)

        self.emit('label', loop_label)
        self.LOOPS.append(('DO', end_loop, continue_loop))  # Saves which labels to jump upon EXIT or CONTINUE

        if len(node.children) > 1:
            yield node.children[1]

        self.emit('label', continue_loop)
        yield node.children[0]  # Condition
        self.emit('jzero' + self.TSUFFIX(node.children[0].type_), node.children[0].t, loop_label)
        self.emit('label', end_loop)
        self.LOOPS.pop()
        # del loop_label, end_loop, continue_loop

    def visit_WHILE(self, node):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        self.LOOPS.append(('WHILE', end_loop, loop_label))  # Saves which labels to jump upon EXIT or CONTINUE

        self.emit('label', loop_label)
        yield node.children[0]
        self.emit('jzero' + self.TSUFFIX(node.children[0].type_), node.children[0].t, end_loop)

        if len(node.children) > 1:
            yield node.children[1]

        self.emit('jump', loop_label)
        self.emit('label', end_loop)
        self.LOOPS.pop()

    def visit_WHILE_DO(self, node):
        return self.visit_DO_WHILE(node)

    # endregion

    # region [Drawing Primitives]
    # -----------------------------------------------------------------------------------------------------
    # Drawing Primitives PLOT, DRAW, DRAW3, CIRCLE
    # -----------------------------------------------------------------------------------------------------
    def visit_PLOT(self, node):
        TMP_HAS_ATTR = self.check_attr(node, 2)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.emit('param' + self.TSUFFIX(node.children[0].type_), node.children[0].t)
        yield node.children[1]
        self.emit('fparam' + self.TSUFFIX(node.children[1].type_), node.children[1].t)
        self.emit('call', 'PLOT', 0)  # Procedure call. Discard return
        backend.REQUIRES.add('plot.asm')
        self.HAS_ATTR = (TMP_HAS_ATTR is not None)

    def visit_DRAW(self, node):
        TMP_HAS_ATTR = self.check_attr(node, 2)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.emit('param' + self.TSUFFIX(node.children[0].type_), node.children[0].t)
        yield node.children[1]
        self.emit('fparam' + self.TSUFFIX(node.children[1].type_), node.children[1].t)
        self.emit('call', 'DRAW', 0)  # Procedure call. Discard return
        backend.REQUIRES.add('draw.asm')
        self.HAS_ATTR = (TMP_HAS_ATTR is not None)

    def visit_DRAW3(self, node):
        TMP_HAS_ATTR = self.check_attr(node, 3)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.emit('param' + self.TSUFFIX(node.children[0].type_), node.children[0].t)
        yield node.children[1]
        self.emit('param' + self.TSUFFIX(node.children[1].type_), node.children[1].t)
        yield node.children[2]
        self.emit('fparam' + self.TSUFFIX(node.children[2].type_), node.children[2].t)
        self.emit('call', 'DRAW3', 0)  # Procedure call. Discard return
        backend.REQUIRES.add('draw3.asm')
        self.HAS_ATTR = (TMP_HAS_ATTR is not None)

    def visit_CIRCLE(self, node):
        TMP_HAS_ATTR = self.check_attr(node, 3)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.emit('param' + self.TSUFFIX(node.children[0].type_), node.children[0].t)
        yield node.children[1]
        self.emit('param' + self.TSUFFIX(node.children[1].type_), node.children[1].t)
        yield node.children[2]
        self.emit('fparam' + self.TSUFFIX(node.children[2].type_), node.children[2].t)
        self.emit('call', 'CIRCLE', 0)  # Procedure call. Discard return
        backend.REQUIRES.add('circle.asm')
        self.HAS_ATTR = (TMP_HAS_ATTR is not None)

    # endregion

    # region [I/O Statements]
    # -----------------------------------------------------------------------------------------------------
    # PRINT, LOAD, SAVE and I/O statements
    # -----------------------------------------------------------------------------------------------------
    def visit_OUT(self, node):
        yield node.children[0]
        yield node.children[1]
        self.emit('out', node.children[0].t, node.children[1].t)

    def visit_PRINT(self, node):
        for i in node.children:
            yield i

            # Print subcommands (AT, OVER, INK, etc... must be skipped here)
            if i.token in ('PRINT_TAB', 'PRINT_AT', 'PRINT_COMMA',) + self.ATTR_TMP:
                continue
            self.emit('fparam' + self.TSUFFIX(i.type_), i.t)
            self.emit('call', '__PRINT' + self.TSUFFIX(i.type_).upper(), 0)
            backend.REQUIRES.add('print' + self.TSUFFIX(i.type_).lower() + '.asm')

        for i in node.children:
            if i.token in self.ATTR_TMP or self.has_control_chars(i):
                self.HAS_ATTR = True
                break

        if node.eol:
            if self.HAS_ATTR:
                self.emit('call', 'PRINT_EOL_ATTR', 0)
                backend.REQUIRES.add('print_eol_attr.asm')
                self.HAS_ATTR = False
            else:
                self.emit('call', 'PRINT_EOL', 0)
                backend.REQUIRES.add('print.asm')
        else:
            self.norm_attr()

    def visit_PRINT_AT(self, node):
        yield node.children[0]
        self.emit('paramu8', node.children[0].t)
        yield node.children[1]
        self.emit('fparamu8', node.children[1].t)
        self.emit('call', 'PRINT_AT', 0)  # Procedure call. Discard return
        backend.REQUIRES.add('print.asm')

    def visit_PRINT_TAB(self, node):
        yield node.children[0]
        self.emit('fparamu8', node.children[0].t)
        self.emit('call', 'PRINT_TAB', 0)
        backend.REQUIRES.add('print.asm')

    def visit_PRINT_COMMA(self, node):
        self.emit('call', 'PRINT_COMMA', 0)
        backend.REQUIRES.add('print.asm')

    def visit_LOAD(self, node):
        yield node.children[0]
        self.emit('paramstr', node.children[0].t)
        yield node.children[1]
        self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), node.children[1].t)
        yield node.children[2]
        self.emit('param' + self.TSUFFIX(gl.PTR_TYPE), node.children[2].t)

        self.emit('paramu8', int(node.token == 'LOAD'))
        self.emit('call', 'LOAD_CODE', 0)
        backend.REQUIRES.add('load.asm')

    def visit_SAVE(self, node):
        yield (node.children[0])
        self.emit('paramstr', node.children[0].t)
        yield (node.children[1])
        self.emit('paramu16', node.children[1].t)
        yield (node.children[2])
        self.emit('paramu16', node.children[2].t)
        self.emit('call', 'SAVE_CODE', 0)
        backend.REQUIRES.add('save.asm')

    def visit_VERIFY(self, node):
        return self.visit_LOAD(node)

    def visit_BORDER(self, node):
        yield node.children[0]
        self.emit('fparamu8', node.children[0].t)
        self.emit('call', 'BORDER', 0)  # Procedure call. Discard return
        backend.REQUIRES.add('border.asm')

    def visit_BEEP(self, node):
        if node.children[0].token == node.children[1].token == 'NUMBER':  # BEEP <const>, <const>
            DE, HL = arch.zx48k.beep.getDEHL(float(node.children[0].t), float(node.children[1].t))
            self.emit('paramu16', HL)
            self.emit('fparamu16', DE)
            self.emit('call', '__BEEPER', 0)  # Procedure call. Discard return
            backend.REQUIRES.add('beeper.asm')
        else:
            yield node.children[1]
            self.emit('paramf', node.children[1].t)
            yield node.children[0]
            self.emit('fparamf', node.children[0].t)
            self.emit('call', 'BEEP', 0)  # Procedure call. Discard return
            backend.REQUIRES.add('beep.asm')

    def visit_PAUSE(self, node):
        yield node.children[0]
        self.emit('fparam' + self.TSUFFIX(node.children[0].type_), node.children[0].t)
        self.emit('call', '__PAUSE', 0)
        backend.REQUIRES.add('pause.asm')

    # endregion

    # region [ATTR Sentences]
    # -----------------------------------------------------------------------
    # ATTR sentences: INK, PAPER, BRIGHT, FLASH, INVERSE, OVER, ITALIC, BOLD
    # -----------------------------------------------------------------------
    def visit_ATTR_sentence(self, node):
        yield node.children[0]
        self.emit('fparamu8', node.children[0].t)
        self.emit('call', node.token, 0)
        backend.REQUIRES.add('%s.asm' % node.token.lower())
        self.HAS_ATTR = True

    def visit_INK(self, node):
        return self.visit_ATTR_sentence(node)

    def visit_PAPER(self, node):
        return self.visit_ATTR_sentence(node)

    def visit_BRIGHT(self, node):
        return self.visit_ATTR_sentence(node)

    def visit_FLASH(self, node):
        return self.visit_ATTR_sentence(node)

    def visit_INVERSE(self, node):
        return self.visit_ATTR_sentence(node)

    def visit_OVER(self, node):
        return self.visit_ATTR_sentence(node)

    def visit_BOLD(self, node):
        return self.visit_ATTR_sentence(node)

    def visit_ITALIC(self, node):
        return self.visit_ATTR_sentence(node)

    # endregion

    # region [Other Sentences]
    # -----------------------------------------------------------------------------------------------------
    # Other Sentences, like ASM, etc..
    # -----------------------------------------------------------------------------------------------------
    def visit_ASM(self, node):
        self.emit('inline', node.asm, node.lineno)

    # endregion

    # region [Helpers]
    # --------------------------------------
    # Helpers
    # --------------------------------------
    def emit_var_assign(self, var, t):
        """ Emits code for storing a value into a variable
        :param var: variable (node) to be updated
        :param t: the value to emmit (e.g. a _label, a const, a tN...)
        """
        p = '*' if var.byref else ''  # Indirection prefix
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

    def emit_let_left_part(self, node, t=None):
        var = node.children[0]
        expr = node.children[1]

        if t is None:
            t = expr.t  # TODO: Check

        return self.emit_var_assign(var, t)

    # endregion

    # region [Static Methods]
    # --------------------------------------
    # Static Methods
    # --------------------------------------
    def loop_exit_label(self, loop_type):
        """ Returns the label for the given loop type which
        exits the loop. loop_type must be one of 'FOR', 'WHILE', 'DO'
        """
        for i in range(len(self.LOOPS) - 1, -1, -1):
            if loop_type == self.LOOPS[i][0]:
                return self.LOOPS[i][1]

        raise InvalidLoopError(loop_type)

    def loop_cont_label(self, loop_type):
        """ Returns the label for the given loop type which
        continues the loop. loop_type must be one of 'FOR', 'WHILE', 'DO'
        """
        for i in range(len(self.LOOPS) - 1, -1, -1):
            if loop_type == self.LOOPS[i][0]:
                return self.LOOPS[i][2]

        raise InvalidLoopError(loop_type)

    @classmethod
    def default_value(cls, type_, expr):  # TODO: This function must be moved to api.xx
        """ Returns a list of bytes (as hexadecimal 2 char string)
        """
        assert isinstance(type_, symbols.TYPE)
        assert type_.is_basic
        assert check.is_static(expr)

        if isinstance(expr, (symbols.CONST, symbols.VAR)):  # a constant expression like @label + 1
            if type_ in (cls.TYPE(TYPE.float_), cls.TYPE(TYPE.string)):
                syntax_error(expr.lineno, "Can't convert non-numeric value to {0} at compile time".format(type_.name))
                return ['<ERROR>']

            val = Translator.traverse_const(expr)
            if type_.size == 1:  # U/byte
                if expr.type_.size != 1:
                    return ['#({0}) & 0xFF'.format(val)]
                else:
                    return ['#{0}'.format(val)]

            if type_.size == 2:  # U/integer
                if expr.type_.size != 2:
                    return ['##({0}) & 0xFFFF'.format(val)]
                else:
                    return ['##{0}'.format(val)]

            if type_ == cls.TYPE(TYPE.fixed):
                return ['0000', '##({0}) & 0xFFFF'.format(val)]

            # U/Long
            return ['##({0}) & 0xFFFF'.format(val), '##(({0}) >> 16) & 0xFFFF'.format(val)]

        if type_ == cls.TYPE(TYPE.float_):
            C, DE, HL = _float(expr.value)
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

        if type_ == cls.TYPE(TYPE.fixed):
            value = 0xFFFFFFFF & int(expr.value * 2 ** 16)
        else:
            value = int(expr.value)

        result = [value, value >> 8, value >> 16, value >> 24]
        result = ['%02X' % (v & 0xFF) for v in result]
        return result[:type_.size]

    @staticmethod
    def array_default_value(type_, values):
        """ Returns a list of bytes (as hexadecimal 2 char string)
        which represents the array initial value.
        """
        if not isinstance(values, list):
            return Translator.default_value(type_, values)

        l = []
        for row in values:
            l.extend(Translator.array_default_value(type_, row))

        return l

    @staticmethod
    def has_control_chars(i):
        """ Returns true if the passed token is an unknown string
        or a constant string having control chars (inverse, etc
        """
        if not hasattr(i, 'type_'):
            return False

        if i.type_ != Type.string:
            return False

        if i.token in ('VAR', 'PARAMDECL'):
            return True  # We don't know what an alphanumeric variable will hold

        if i.token == 'STRING':
            for c in i.value:
                if 15 < ord(c) < 22:  # is it an attr char?
                    return True
            return False

        for j in i.children:
            if Translator.has_control_chars(j):
                return True

        return False

    # endregion
    """ END """


class VarTranslator(TranslatorVisitor):
    """ Var Translator
    This translator emits memory var space
    """

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
                if isinstance(entry.default_value, symbols.CONST) and entry.default_value.token == 'CONST':
                    self.emit('varx', node.mangled, self.TSUFFIX(node.type_),
                              [self.traverse_const(entry.default_value)])
                else:
                    self.emit('vard', node.mangled, Translator.default_value(node.type_, entry.default_value))

    def visit_ARRAYDECL(self, node):
        entry = node.entry
        assert entry.default_value is None or entry.addr is None, "Cannot use address and default_value at once"

        if not entry.accessed:
            api.errmsg.warning_not_used(entry.lineno, entry.name)
            if self.O_LEVEL > 1:
                return

        data_label = entry.data_label
        idx_table_label = backend.tmp_label()
        l = ['%04X' % (len(node.bounds) - 1)]  # Number of dimensions - 1

        for bound in node.bounds[1:]:
            l.append('%04X' % (bound.upper - bound.lower + 1))

        l.append('%02X' % node.type_.size)
        arr_data = []

        if entry.addr:
            self.emit('deflabel', data_label, "%s" % entry.addr)
        else:
            if entry.default_value is not None:
                arr_data = Translator.array_default_value(node.type_, entry.default_value)
            else:
                arr_data = ['00'] * node.size

        for alias in entry.aliased_by:
            offset = 1 + 2 * entry.count + alias.offset  # TODO: Generalize for multi-arch
            self.emit('deflabel', alias.mangled, '%s + %i' % (entry.mangled, offset))

        self.emit('varx', node.mangled, self.TSUFFIX(gl.PTR_TYPE), [idx_table_label])

        if entry.addr:
            self.emit('varx', entry.data_ptr_label, self.TSUFFIX(gl.PTR_TYPE), [self.traverse_const(entry.addr)])
        else:
            self.emit('varx', entry.data_ptr_label, self.TSUFFIX(gl.PTR_TYPE), [data_label])
            self.emit('vard', data_label, arr_data)

        self.emit('vard', idx_table_label, l)

        if entry.lbound_used:
            l = ['%04X' % len(node.bounds)] + \
                ['%04X' % bound.lower for bound in node.bounds]
            self.emit('vard', '__LBOUND__.' + entry.mangled, l)

        if entry.ubound_used:
            l = ['%04X' % len(node.bounds)] + \
                ['%04X' % bound.upper for bound in node.bounds]
            self.emit('vard', '__UBOUND__.' + entry.mangled, l)


class UnaryOpTranslator(TranslatorVisitor):
    """ UNARY sub-visitor. E.g. -a or bNot pi
    """

    def visit_MINUS(self, node):
        yield node.operand
        self.emit('neg' + self.TSUFFIX(node.type_), node.t, node.operand.t)

    def visit_NOT(self, node):
        yield node.operand
        self.emit('not' + self.TSUFFIX(node.operand.type_), node.t, node.operand.t)

    def visit_BNOT(self, node):
        yield node.operand
        self.emit('bnot' + self.TSUFFIX(node.operand.type_), node.t, node.operand.t)

    def visit_ADDRESS(self, node):
        scope = node.children[0].scope
        if node.children[0].token == 'ARRAYACCESS':
            yield node.children[0]
            # Address of an array element.
            if scope == SCOPE.global_:
                self.emit('aaddr', node.t, node.children[0].entry.mangled)
            elif scope == 'parameter':
                self.emit('paaddr', node.t, node.children[0].entry.offset)
            elif scope == 'local':
                self.emit('paaddr', node.t, -node.children[0].entry.offset)
        else:  # It's a scalar variable
            if scope == SCOPE.global_:
                self.emit('load' + self.TSUFFIX(node.type_), node.t, '#' + node.operand.t)
            elif scope == SCOPE.parameter:
                self.emit('paddr', node.operand.offset + node.operand.type_.size % 2, node.t)
            elif scope == SCOPE.local:
                self.emit('paddr', -node.operand.offset, node.t)


class BuiltinTranslator(TranslatorVisitor):
    """ BUILTIN functions visitor. Eg. LEN(a$) or SIN(x)
    """
    REQUIRES = backend.REQUIRES

    # region STRING Functions
    def visit_INKEY(self, node):
        self.emit('call', 'INKEY', Type.string.size)
        backend.REQUIRES.add('inkey.asm')

    def visit_IN(self, node):
        self.emit('in', node.children[0].t)

    def visit_CODE(self, node):
        self.emit('fparam' + self.TSUFFIX(gl.PTR_TYPE), node.operand.t)
        if node.operand.token != 'STRING' and node.operand.token != 'VAR' and node.operand.t != '_':
            self.emit('fparamu8', 1)  # If the argument is not a variable, it must be freed
        else:
            self.emit('fparamu8', 0)

        self.emit('call', '__ASC', Type.ubyte.size)  # Expect a char code
        backend.REQUIRES.add('asc.asm')

    def visit_CHR(self, node):
        self.emit('fparam' + self.TSUFFIX(gl.STR_INDEX_TYPE), len(node.operand))  # Number of args
        self.emit('call', 'CHR', node.size)
        backend.REQUIRES.add('chr.asm')

    def visit_STR(self, node):
        self.emit('fparamf', node.children[0].t)
        self.emit('call', '__STR_FAST', node.type_.size)
        backend.REQUIRES.add('str.asm')

    def visit_LEN(self, node):
        self.emit('lenstr', node.t, node.operand.t)

    def visit_VAL(self, node):
        self.emit('fparam' + self.TSUFFIX(gl.PTR_TYPE), node.operand.t)
        if node.operand.token not in ('STRING', 'VAR') and node.operand.t != '_':
            self.emit('fparamu8', 1)  # If the argument is not a variable, it must be freed
        else:
            self.emit('fparamu8', 0)

        self.emit('call', 'VAL', node.type_.size)
        backend.REQUIRES.add('val.asm')

    def visit_ABS(self, node):
        self.emit('abs' + self.TSUFFIX(node.children[0].type_), node.t, node.children[0].t)

    def visit_RND(self, node):  # A special "ZEROARY" function with no parameters
        self.emit('call', 'RND', Type.float_.size)
        backend.REQUIRES.add('random.asm')

    # endregion

    def visit_PEEK(self, node):
        self.emit('load' + self.TSUFFIX(node.type_), node.t, '*' + str(node.children[0].t))

    # region MATH Functions
    def visit_SIN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'SIN', node.size)
        self.REQUIRES.add('sin.asm')

    def visit_COS(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'COS', node.size)
        self.REQUIRES.add('cos.asm')

    def visit_TAN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'TAN', node.size)
        self.REQUIRES.add('tan.asm')

    def visit_ASN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'ASIN', node.size)
        self.REQUIRES.add('asin.asm')

    def visit_ACS(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'ACOS', node.size)
        self.REQUIRES.add('acos.asm')

    def visit_ATN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'ATAN', node.size)
        self.REQUIRES.add('atan.asm')

    def visit_EXP(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'EXP', node.size)
        self.REQUIRES.add('exp.asm')

    def visit_LN(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'LN', node.size)
        self.REQUIRES.add('logn.asm')

    def visit_SGN(self, node):
        s = self.TSUFFIX(node.operand.type_)
        self.emit('fparam' + s, node.operand.t)
        self.emit('call', '__SGN%s' % s.upper(), node.size)
        self.REQUIRES.add('sgn%s.asm' % s)

    def visit_SQR(self, node):
        self.emit('fparam' + self.TSUFFIX(node.operand.type_), node.operand.t)
        self.emit('call', 'SQRT', node.size)
        self.REQUIRES.add('sqrt.asm')

    # endregion

    def visit_LBOUND(self, node):
        entry = node.operands[0]
        self.emit('param' + self.TSUFFIX(gl.BOUND_TYPE), '#__LBOUND__.' + entry.mangled)
        yield node.operands[1]
        self.emit('fparam' + self.TSUFFIX(gl.BOUND_TYPE), optemps.new_t())
        self.emit('call', '__BOUND', self.TYPE(gl.BOUND_TYPE).size)
        backend.REQUIRES.add('bound.asm')

    def visit_UBOUND(self, node):
        entry = node.operands[0]
        self.emit('param' + self.TSUFFIX(gl.BOUND_TYPE), '#__UBOUND__.' + entry.mangled)
        yield node.operands[1]
        self.emit('fparam' + self.TSUFFIX(gl.BOUND_TYPE), optemps.new_t())
        self.emit('call', '__BOUND', self.TYPE(gl.BOUND_TYPE).size)
        backend.REQUIRES.add('bound.asm')

    def visit_USR_STR(self, node):
        # USR ADDR
        self.emit('fparamstr', node.children[0].t)
        self.emit('call', 'USR_STR', node.type_.size)
        backend.REQUIRES.add('usr_str.asm')

    def visit_USR(self, node):
        """ Machine code call from basic
        """
        self.emit('fparam' + self.TSUFFIX(gl.PTR_TYPE), node.children[0].t)
        self.emit('call', 'USR', node.type_.size)
        backend.REQUIRES.add('usr.asm')


class FunctionTranslator(Translator):
    REQUIRES = backend.REQUIRES

    def __init__(self, function_list):
        if function_list is None:
            function_list = []
        super(FunctionTranslator, self).__init__()

        assert isinstance(function_list, list)
        for x in function_list:
            assert isinstance(x, symbols.FUNCTION)
        self.functions = function_list

    def start(self):
        while self.functions:
            f = self.functions.pop(0)
            __DEBUG__('Translating function ' + f.__repr__())
            self.visit(f)

    def visit_FUNCTION(self, node):
        self.emit('label', node.mangled)
        if node.convention == CONVENTION.fastcall:
            self.emit('enter', '__fastcall__')
        else:
            self.emit('enter', node.locals_size)

        for local_var in node.local_symbol_table.values():
            if not local_var.accessed:  # HINT: This should never happens as values() is already filtered
                api.errmsg.warning_not_used(local_var.lineno, local_var.name)
                # HINT: Cannot optimize local variables now, since the offsets are already calculated
                # if self.O_LEVEL > 1:
                #    return

            if local_var.class_ == CLASS.array and local_var.scope != SCOPE.global_:
                l = [len(local_var.bounds) - 1] + [x.count for x in local_var.bounds[1:]]  # TODO Check this
                q = []
                for x in l:
                    q.append('%02X' % (x & 0xFF))
                    q.append('%02X' % (x >> 8))

                q.append('%02X' % local_var.type_.size)
                r = []
                if local_var.default_value is not None:
                    r.extend(self.array_default_value(local_var.type_, local_var.default_value))
                self.emit('larrd', local_var.offset, q, local_var.size, r)  # Initializes array bounds
            elif local_var.class_ == CLASS.const:
                continue
            else:  # Local vars always defaults to 0, so if 0 we do nothing
                if local_var.default_value is not None and local_var.default_value != 0:
                    if isinstance(local_var.default_value, symbols.CONST) and \
                            local_var.default_value.token == 'CONST':
                        self.emit('lvarx', local_var.offset, self.TSUFFIX(local_var.type_),
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
            scope = local_var.scope
            if local_var.type_ == self.TYPE(TYPE.string):  # Only if it's string we free it
                if local_var.class_ != CLASS.array:  # Ok just free it
                    if scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref):
                        if not preserve_hl:
                            preserve_hl = True
                            self.emit('exchg')

                        offset = -local_var.offset if scope == SCOPE.local else local_var.offset
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

                        self.emit('param' + self.TSUFFIX(gl.BOUND_TYPE), local_var.count)
                        t2 = optemps.new_t()
                        if scope == SCOPE.parameter:
                            self.emit('pload%s' % self.TSUFFIX(gl.PTR_TYPE), t2,
                                      '%i' % (local_var.offset - self.TYPE(gl.PTR_TYPE).size))
                        elif scope == SCOPE.local:
                            self.emit('pload%s' % self.TSUFFIX(gl.PTR_TYPE), t2,
                                      '%i' % -(local_var.offset - self.TYPE(gl.PTR_TYPE).size))
                        self.emit('fparam' + self.TSUFFIX(gl.PTR_TYPE), t2)
                        self.emit('call', '__ARRAYSTR_FREE_MEM', 0)  # frees all the strings and the array itself
                        self.REQUIRES.add('arraystrfree.asm')

            if local_var.class_ == CLASS.array and local_var.type_ != self.TYPE(TYPE.string) and \
                    (scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref)):
                if not preserve_hl:
                    preserve_hl = True
                    self.emit('exchg')

                t2 = optemps.new_t()
                if scope == SCOPE.parameter:
                    self.emit('pload%s' % self.TSUFFIX(gl.PTR_TYPE), t2, '%i'
                              % (local_var.offset - self.TYPE(gl.PTR_TYPE).size))
                elif scope == SCOPE.local:
                    self.emit('pload%s' % self.TSUFFIX(gl.PTR_TYPE), t2, '%i'
                              % -(local_var.offset - self.TYPE(gl.PTR_TYPE).size))

                self.emit('fparam' + self.TSUFFIX(gl.PTR_TYPE), t2)
                self.emit('call', '__MEM_FREE', 0)
                self.REQUIRES.add('free.asm')

        if preserve_hl:
            self.emit('exchg')

        if node.convention == CONVENTION.fastcall:
            self.emit('leave', CONVENTION.to_string(node.convention))
        else:
            self.emit('leave', node.params.size)

    def visit_FUNCDECL(self, node):
        """ Nested scope functions
        """
        self.functions.append(node.entry)
