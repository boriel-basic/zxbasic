#!/usr/bin/env python
# -*- coding: utf-8 -*-

from collections import namedtuple

from src.api.constants import TYPE
from src.api.constants import SCOPE
from src.api.constants import CLASS
from src.api.constants import CONVENTION

import src.api.errmsg
import src.api.global_ as gl
import src.api.check as check

from src.api.debug import __DEBUG__
from src.api.errmsg import error
from src.api.config import OPTIONS
from src.api.global_ import optemps
from src.api.errors import InvalidLoopError
from src.api.errors import InvalidOperatorError
from src.api.errors import InvalidBuiltinFunctionError
from src.api.errors import InternalError
from src.zxbpp import zxbpp

from src.arch.z80 import backend
from src.arch.z80.backend.runtime import Labels as RuntimeLabel
from src.arch.z80.backend._float import _float
from src.arch.z80.translatorvisitor import TranslatorVisitor, JumpTable

from src import symbols
from src.symbols.type_ import Type

__all__ = ["Translator", "VarTranslator", "FunctionTranslator"]

LabelledData = namedtuple("LabelledData", ("label", "data"))


class Translator(TranslatorVisitor):
    """ZX Spectrum translator"""

    def visit_NOP(self, node):
        pass  # nothing to do

    def visit_CLS(self, node):
        self.runtime_call(RuntimeLabel.CLS, 0)

    def visit_NUMBER(self, node):
        __DEBUG__("NUMBER " + str(node))
        yield node.value

    def visit_STRING(self, node):
        __DEBUG__("STRING " + str(node))
        node.t = "#" + self.add_string_label(node.value)
        yield node.t

    def visit_END(self, node):
        yield node.children[0]
        __DEBUG__("END")
        self.ic_end(node.children[0].t)

    def visit_ERROR(self, node):
        # Raises an error
        yield node.children[0]
        self.ic_fparam(TYPE.ubyte, node.children[0].t)
        self.runtime_call(RuntimeLabel.ERROR, 0)

    def visit_STOP(self, node):
        """Returns to BASIC with an error code"""
        yield node.children[0]
        self.ic_fparam(TYPE.ubyte, node.children[0].t)
        self.runtime_call(RuntimeLabel.STOP, 0)
        self.ic_end(0)

    def visit_LET(self, node):
        assert isinstance(node.children[0], symbols.VAR)
        if self.O_LEVEL < 2 or node.children[0].accessed or node.children[1].token == "CONST":
            yield node.children[1]
        __DEBUG__("LET")
        self.emit_let_left_part(node)

    def visit_POKE(self, node):
        ch0 = node.children[0]
        ch1 = node.children[1]
        yield ch0
        yield ch1

        if ch0.token == "VAR" and ch0.class_ != CLASS.const and ch0.scope == SCOPE.global_:
            self.ic_store(ch1.type_, "*" + str(ch0.t), ch1.t)
        else:
            self.ic_store(ch1.type_, str(ch0.t), ch1.t)

    def visit_RANDOMIZE(self, node):
        yield node.children[0]
        self.ic_fparam(node.children[0].type_, node.children[0].t)
        self.runtime_call(RuntimeLabel.RANDOMIZE, 0)

    def visit_LABEL(self, node):
        self.ic_label(node.mangled)
        for tmp in node.aliased_by:
            self.ic_label(tmp.mangled)

    def visit_VAR(self, node):
        __DEBUG__(
            "{}: VAR {}:{} Scope: {} Class: {}".format(
                node.lineno, node.name, node.type_, SCOPE.to_string(node.scope), CLASS.to_string(node.class_)
            )
        )
        scope = node.scope

        if node.t == node.mangled and scope == SCOPE.global_:
            return

        if node.class_ in (CLASS.label, CLASS.const):
            return

        p = "*" if node.byref else ""  # Indirection prefix

        if scope == SCOPE.parameter:
            self.ic_pload(node.type_, node.t, p + str(node.offset))
        elif scope == SCOPE.local:
            offset = node.offset
            if node.alias is not None and node.alias.class_ == CLASS.array:
                offset -= 1 + 2 * node.alias.count  # TODO this is actually NOT implemented

            self.ic_pload(node.type_, node.t, p + str(-offset))

    def visit_CONST(self, node):
        node.t = "#" + (self.traverse_const(node) or "")
        yield node.t

    def visit_VARARRAY(self, node):
        pass

    def visit_PARAMDECL(self, node):
        assert node.scope == SCOPE.parameter
        self.visit_VAR(node)

    def visit_UNARY(self, node):
        uvisitor = UnaryOpTranslator()
        att = "visit_{}".format(node.operator)
        if hasattr(uvisitor, att):
            yield getattr(uvisitor, att)(node)
            return

        raise InvalidOperatorError(node.operator)

    def visit_BUILTIN(self, node):
        yield node.operand
        bvisitor = BuiltinTranslator()
        att = "visit_{}".format(node.fname)
        if hasattr(bvisitor, att):
            yield getattr(bvisitor, att)(node)
            return

        raise InvalidBuiltinFunctionError(node.fname)

    def visit_BINARY(self, node):
        yield node.left
        yield node.right

        ins = {"PLUS": "add", "MINUS": "sub"}.get(node.operator, node.operator.lower())
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

    def visit_CALL(self, node: symbols.CALL):
        yield node.args  # arglist
        if node.entry.convention == CONVENTION.fastcall:
            if len(node.args) > 0:  # At least 1 parameter
                self.ic_fparam(node.args[0].type_, optemps.new_t())

        self.ic_call(node.entry.mangled, 0)  # Procedure call. 0 = discard return
        if node.entry.class_ == CLASS.function and node.entry.type_ == self.TYPE(TYPE.string):
            self.runtime_call(RuntimeLabel.MEM_FREE, 0)  # Discard string return value if the called function has any

    def visit_ARGLIST(self, node):
        for i in range(len(node) - 1, -1, -1):  # visit in reverse order
            yield node[i]

            if (
                isinstance(node.parent, symbols.ARRAYACCESS)
                and OPTIONS.array_check
                and node.parent.entry.scope != SCOPE.parameter
            ):
                upper = node.parent.entry.bounds[i].upper
                lower = node.parent.entry.bounds[i].lower
                self.ic_param(gl.PTR_TYPE, upper - lower)

    def visit_ARGUMENT(self, node):
        if not node.byref:
            if node.value.token in ("VAR", "PARAMDECL") and node.type_.is_dynamic and node.value.t[0] == "$":
                # Duplicate it in the heap
                assert node.value.scope in (SCOPE.local, SCOPE.parameter)
                if node.value.scope == SCOPE.local:
                    self.ic_pload(node.type_, node.t, str(-node.value.offset))
                else:  # PARAMETER
                    self.ic_pload(node.type_, node.t, str(node.value.offset))
            else:
                yield node.value
            self.ic_param(node.type_, node.t)
        else:
            scope = node.value.scope
            if node.t[0] == "_":
                t = optemps.new_t()
            else:
                t = node.t

            if scope == SCOPE.global_:
                self.ic_load(TYPE.uinteger, t, "#" + node.mangled)
            elif scope == SCOPE.parameter:  # A function has used a parameter as an argument to another function call
                if not node.value.byref:  # It's like a local variable
                    offset = 1 if node.type_ in (Type.byte_, Type.ubyte) else 0
                    self.ic_paddr(node.value.offset + offset, t)
                else:
                    self.ic_pload(gl.PTR_TYPE, t, str(node.value.offset))
            elif scope == SCOPE.local:
                self.ic_paddr(-node.value.offset, t)

            self.ic_param(TYPE.uinteger, t)

    def visit_ARRAYLOAD(self, node):
        scope = node.entry.scope

        if node.offset is None:
            yield node.args

            if scope == SCOPE.global_:
                self.ic_aload(node.type_, node.entry.t, node.entry.mangled)
            elif scope == SCOPE.parameter:
                self.ic_paload(node.type_, node.t, "*{}".format(node.entry.offset))
            elif scope == SCOPE.local:
                self.ic_paload(node.type_, node.t, -node.entry.offset)
        else:
            offset = node.offset
            if scope == SCOPE.global_:
                self.ic_load(node.type_, node.entry.t, "%s + %i" % (node.entry.t, offset))
            elif scope == SCOPE.parameter:
                self.ic_pload(node.type_, node.t, node.entry.offset - offset)
            elif scope == SCOPE.local:
                t1 = optemps.new_t()
                t2 = optemps.new_t()
                t3 = optemps.new_t()
                self.ic_pload(gl.PTR_TYPE, t1, -(node.entry.offset - self.TYPE(gl.PTR_TYPE).size))
                self.ic_add(gl.PTR_TYPE, t2, t1, node.offset)
                self.ic_load(node.type_, t3, "*$%s" % t2)

    def _emit_arraycopy_child(self, child: symbols.VARARRAY):
        scope = child.scope
        if scope == SCOPE.global_:
            t = "#%s" % child.data_label
        elif scope == SCOPE.parameter:
            t = optemps.new_t()
            self.ic_pload(gl.PTR_TYPE, t, "%i" % (child.offset - self.TYPE(gl.PTR_TYPE).size))
        else:
            t = optemps.new_t()
            self.ic_pload(gl.PTR_TYPE, t, "%i" % -(child.offset - self.TYPE(gl.PTR_TYPE).size))
        return t

    def visit_ARRAYCOPY(self, node):
        t1 = self._emit_arraycopy_child(node.children[0])
        t2 = self._emit_arraycopy_child(node.children[1])

        tr = node.children[1]
        t = optemps.new_t()
        if tr.type_ != Type.string:
            self.ic_load(gl.PTR_TYPE, t, "%i" % tr.size)
            self.ic_memcopy(t1, t2, t)
        else:
            self.ic_load(gl.PTR_TYPE, t, "%i" % tr.count)
            self.runtime_call(RuntimeLabel.STR_ARRAYCOPY, 0)

    def visit_LETARRAY(self, node):
        if self.O_LEVEL > 1 and not node.children[0].entry.accessed:
            return

        arr = node.children[0]  # Array access
        scope = arr.scope

        if arr.offset is None:
            yield node.children[1]  # Right expression
            yield arr

            if scope == SCOPE.global_:
                self.ic_astore(arr.type_, arr.entry.mangled, node.children[1].t)
            elif scope == SCOPE.parameter:
                # HINT: Arrays are always passed ByREF
                self.ic_pastore(arr.type_, "*{}".format(arr.entry.offset), node.children[1].t)
            elif scope == SCOPE.local:
                self.ic_pastore(arr.type_, -arr.entry.offset, node.children[1].t)
        else:
            name = arr.entry.data_label
            if scope == SCOPE.global_:
                yield node.children[1]  # Right expression
                self.ic_store(arr.type_, "%s + %i" % (name, arr.offset), node.children[1].t)
            elif scope == SCOPE.local:
                t1 = optemps.new_t()
                t2 = optemps.new_t()
                self.ic_pload(gl.PTR_TYPE, t1, -(arr.entry.offset - self.TYPE(gl.PTR_TYPE).size))
                self.ic_add(gl.PTR_TYPE, t2, t1, arr.offset)
                yield node.children[1]  # Right expression

                if arr.type_ == Type.string:
                    self.ic_store(arr.type_, f"*{t2}", node.children[1].t)
                else:
                    self.ic_store(arr.type_, t2, node.children[1].t)
            else:
                raise InternalError("Invalid scope {} for variable '{}'".format(scope, arr.entry.name))

    def visit_LETSUBSTR(self, node):
        """LET X$(a TO b) = Y$"""
        # load Y$
        yield node.children[3]

        if check.is_temporary_value(node.children[3]):
            self.ic_param(TYPE.string, node.children[3].t)
            self.ic_param(TYPE.ubyte, 1)
        else:
            self.ic_param(gl.PTR_TYPE, node.children[3].t)
            self.ic_param(TYPE.ubyte, 0)

        # Load a
        yield node.children[1]
        self.ic_param(gl.PTR_TYPE, node.children[1].t)
        # Load b
        yield node.children[2]
        self.ic_param(gl.PTR_TYPE, node.children[2].t)
        # Load x$
        str_var = node.children[0]
        scope = str_var.scope

        if scope == SCOPE.global_:
            self.ic_fparam(gl.PTR_TYPE, str_var.t)
        elif scope == SCOPE.local:
            self.ic_pload(gl.PTR_TYPE, str_var.t, -str_var.offset)
            self.ic_fparam(gl.PTR_TYPE, f"{str_var.t}")
        elif scope == SCOPE.parameter:
            self.ic_pload(gl.PTR_TYPE, str_var.t, str_var.offset)
            if str_var.byref:
                self.ic_fparam(gl.PTR_TYPE, f"*{str_var.t}")
            else:
                self.ic_fparam(gl.PTR_TYPE, f"{str_var.t}")
        else:
            raise InternalError("Invalid scope {} for variable '{}'".format(scope, node.name))

        self.runtime_call(RuntimeLabel.LETSUBSTR, 0)

    def visit_LETARRAYSUBSTR(self, node):
        if self.O_LEVEL > 1 and not node.children[0].entry.accessed:
            return

        expr = node.children[3]  # right expression
        yield expr

        if check.is_temporary_value(expr):
            self.ic_param(TYPE.string, expr.t)
            self.ic_param(TYPE.ubyte, 1)
        else:
            self.ic_param(gl.PTR_TYPE, expr.t)
            self.ic_param(TYPE.ubyte, 0)

        yield node.children[1]
        self.ic_param(gl.PTR_TYPE, node.children[1].t)
        yield node.children[2]
        self.ic_param(gl.PTR_TYPE, node.children[2].t)

        node_ = node.children[0]
        scope = node_.scope
        entry = node_.entry

        # Address of an array element.
        if node_.offset is None:
            yield node_
            if scope == SCOPE.global_:
                self.ic_aload(gl.PTR_TYPE, node_.t, entry.mangled)
            elif scope == SCOPE.parameter:  # TODO: These 2 are never used!??
                self.ic_paload(gl.PTR_TYPE, node_.t, entry.offset)
            elif scope == SCOPE.local:
                self.ic_paload(gl.PTR_TYPE, node_.t, -entry.offset)
        else:
            offset = node_.offset
            if scope == SCOPE.global_:
                self.ic_load(gl.PTR_TYPE, entry.t, "%s.__DATA__ + %i" % (entry.mangled, offset))
            elif scope == SCOPE.parameter:
                self.ic_pload(gl.PTR_TYPE, node_.t, entry.offset - offset)
            elif scope == SCOPE.local:
                self.ic_pload(gl.PTR_TYPE, node_.t, -(entry.offset - offset))

        self.ic_fparam(gl.PTR_TYPE, node.children[0].t)
        self.runtime_call(RuntimeLabel.LETSUBSTR, 0)

    def visit_ARRAYACCESS(self, node):
        yield node.arglist

    def visit_STRSLICE(self, node):
        yield node.string
        if node.string.token == "STRING" or node.string.token == "VAR" and node.string.scope == SCOPE.global_:
            self.ic_param(gl.PTR_TYPE, node.string.t)

        # Now emit the slicing indexes
        yield node.lower
        self.ic_param(node.lower.type_, node.lower.t)

        yield node.upper
        self.ic_param(node.upper.type_, node.upper.t)

        if node.string.token in ("VAR", "PARAMDECL") and node.string.mangled[0] == "_" or node.string.token == "STRING":
            self.ic_fparam(TYPE.ubyte, 0)
        else:
            self.ic_fparam(TYPE.ubyte, 1)  # If the argument is not a variable, it must be freed

        self.runtime_call(RuntimeLabel.STRSLICE, self.TYPE(gl.PTR_TYPE).size)

    def visit_FUNCCALL(self, node):
        yield node.args

        if node.entry.convention == CONVENTION.fastcall:
            if len(node.args) > 0:  # At least 1
                self.ic_fparam(node.args[0].type_, optemps.new_t())

        self.ic_call(node.entry.mangled, node.entry.size)

    def visit_RESTORE(self, node):
        if not gl.DATA_IS_USED:
            return  # If no READ is used, ignore all DATA related statements

        if not node.args:  # No label?
            if not gl.DATAS:
                src.api.errmsg.syntax_error_no_data_defined(node.lineno)
                return

            lbl = gl.DATAS[0].label.name
            type_ = gl.PTR_TYPE
        else:
            lbl = gl.DATA_LABELS[node.args[0].name]
            type_ = node.args[0].type_

        gl.DATA_LABELS_REQUIRED.add(lbl)
        self.ic_fparam(type_, "#" + lbl)
        self.runtime_call(RuntimeLabel.RESTORE, 0)

    def visit_READ(self, node):
        self.ic_fparam(TYPE.ubyte, "#" + str(self.DATA_TYPES[self.TSUFFIX(node.args[0].type_)]))
        self.runtime_call(RuntimeLabel.READ, node.args[0].type_.size)

        if isinstance(node.args[0], symbols.ARRAYACCESS):
            arr = node.args[0]
            t = src.api.global_.optemps.new_t()
            scope = arr.scope

            if arr.offset is None:
                yield arr

                if scope == SCOPE.global_:
                    self.ic_astore(arr.type_, arr.entry.mangled, t)
                elif scope == SCOPE.parameter:
                    self.ic_pastore(arr.type_, arr.entry.offset, t)
                elif scope == SCOPE.local:
                    self.ic_pastore(arr.type_, -arr.entry.offset, t)
            else:
                name = arr.entry.mangled
                if scope == SCOPE.global_:
                    self.ic_store(arr.type_, "%s + %i" % (name, arr.offset), t)
                elif scope == SCOPE.parameter:
                    self.ic_pstore(arr.type_, arr.entry.offset - arr.offset, t)
                elif scope == SCOPE.local:
                    self.ic_pstore(arr.type_, -(arr.entry.offset - arr.offset), t)
        else:
            self.emit_var_assign(node.args[0], t=src.api.global_.optemps.new_t())

    # region Control Flow Sentences
    # -----------------------------------------------------------------------------------------------------
    # Control Flow Compound sentences FOR, IF, WHILE, DO UNTIL...
    # -----------------------------------------------------------------------------------------------------
    def visit_DO_LOOP(self, node):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        self.LOOPS.append(("DO", end_loop, loop_label))  # Saves which labels to jump upon EXIT or CONTINUE

        self.ic_label(loop_label)
        if node.children:
            yield node.children[0]

        self.ic_jump(loop_label)
        self.ic_label(end_loop)
        self.LOOPS.pop()
        # del loop_label, end_loop

    def visit_DO_UNTIL(self, node):
        return self.visit_UNTIL_DO(node)

    def visit_DO_WHILE(self, node):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        continue_loop = backend.tmp_label()

        if node.token == "WHILE_DO":
            self.ic_jump(continue_loop)

        self.ic_label(loop_label)
        self.LOOPS.append(("DO", end_loop, continue_loop))  # Saves which labels to jump upon EXIT or CONTINUE

        if len(node.children) > 1:
            yield node.children[1]

        self.ic_label(continue_loop)
        yield node.children[0]
        self.ic_jnzero(node.children[0].type_, node.children[0].t, loop_label)
        self.ic_label(end_loop)
        self.LOOPS.pop()
        # del loop_label, end_loop, continue_loop

    def visit_EXIT_DO(self, node):
        self.ic_jump(self.loop_exit_label("DO"))

    def visit_EXIT_WHILE(self, node):
        self.ic_jump(self.loop_exit_label("WHILE"))

    def visit_EXIT_FOR(self, node):
        self.ic_jump(self.loop_exit_label("FOR"))

    def visit_CONTINUE_DO(self, node):
        self.ic_jump(self.loop_cont_label("DO"))

    def visit_CONTINUE_WHILE(self, node):
        self.ic_jump(self.loop_cont_label("WHILE"))

    def visit_CONTINUE_FOR(self, node):
        self.ic_jump(self.loop_cont_label("FOR"))

    def visit_FOR(self, node):
        loop_label_start = backend.tmp_label()
        loop_label_gt = backend.tmp_label()
        end_loop = backend.tmp_label()
        loop_body = backend.tmp_label()
        loop_continue = backend.tmp_label()
        type_ = node.children[0].type_

        self.LOOPS.append(("FOR", end_loop, loop_continue))  # Saves which label to jump upon EXIT FOR and CONTINUE FOR

        yield node.children[1]  # Gets starting value (lower limit)
        self.emit_let_left_part(node)  # Stores it in the iterator variable
        self.ic_jump(loop_label_start)

        # FOR body statements
        self.ic_label(loop_body)
        yield node.children[4]

        # Jump here to continue next iteration
        self.ic_label(loop_continue)

        # VAR = VAR + STEP
        yield node.children[0]  # Iterator Var
        yield node.children[3]  # Step
        t = optemps.new_t()
        self.ic_add(type_, t, node.children[0].t, node.children[3].t)
        self.emit_let_left_part(node, t)

        # Loop starts here
        self.ic_label(loop_label_start)

        # Emmit condition
        if check.is_number(node.children[3]) or check.is_unsigned(node.children[3].type_):
            direct = True
        else:
            direct = False
            yield node.children[3]  # Step
            self.ic_jgezero(type_, node.children[3].t, loop_label_gt)

        if not direct or node.children[3].value < 0:  # Here for negative steps
            # Compares if var < limit2
            yield node.children[0]  # Value of var
            yield node.children[2]  # Value of limit2
            self.ic_lt(type_, node.t, node.children[0].t, node.children[2].t)
            self.ic_jzero(TYPE.ubyte, node.t, loop_body)

        if not direct:
            self.ic_jump(end_loop)
            self.ic_label(loop_label_gt)

        if not direct or node.children[3].value >= 0:  # Here for positive steps
            # Compares if var > limit2
            yield node.children[0]  # Value of var
            yield node.children[2]  # Value of limit2
            self.ic_gt(type_, node.t, node.children[0].t, node.children[2].t)
            self.ic_jzero(TYPE.ubyte, node.t, loop_body)

        self.ic_label(end_loop)
        self.LOOPS.pop()

    def visit_GOTO(self, node):
        self.ic_jump(node.children[0].mangled)

    def visit_GOSUB(self, node):
        self.ic_call(node.children[0].mangled, 0)

    def visit_ON_GOTO(self, node):
        table_label = backend.tmp_label()
        self.ic_param(gl.PTR_TYPE, "#" + table_label)
        yield node.children[0]
        self.ic_fparam(node.children[0].type_, node.children[0].t)
        self.runtime_call(RuntimeLabel.ON_GOTO, 0)
        self.JUMP_TABLES.append(JumpTable(table_label, node.children[1:]))

    def visit_ON_GOSUB(self, node):
        table_label = backend.tmp_label()
        self.ic_param(gl.PTR_TYPE, "#" + table_label)
        yield node.children[0]
        self.ic_fparam(node.children[0].type_, node.children[0].t)
        self.runtime_call(RuntimeLabel.ON_GOSUB, 0)
        self.JUMP_TABLES.append(JumpTable(table_label, node.children[1:]))

    def visit_CHKBREAK(self, node):
        if self.PREV_TOKEN != node.token:
            self.ic_inline("push hl")
            self.ic_fparam(gl.PTR_TYPE, node.children[0].t)
            self.runtime_call(RuntimeLabel.CHECK_BREAK, 0)

    def visit_IF(self, node):
        assert 1 < len(node.children) < 4, "IF nodes: %i" % len(node.children)
        yield node.children[0]
        if_label_else = backend.tmp_label()
        if_label_endif = backend.tmp_label()

        if len(node.children) == 3:  # Has else?
            self.ic_jzero(node.children[0].type_, node.children[0].t, if_label_else)
        else:
            self.ic_jzero(node.children[0].type_, node.children[0].t, if_label_endif)

        yield node.children[1]  # THEN...

        if len(node.children) == 3:  # Has else?
            self.ic_jump(if_label_endif)
            self.ic_label(if_label_else)
            yield node.children[2]

        self.ic_label(if_label_endif)

    def visit_RETURN(self, node):
        if len(node.children) == 2:  # Something to return?
            yield node.children[1]
            self.ic_ret(node.children[1].type_, node.children[1].t, "%s__leave" % node.children[0].mangled)
        elif len(node.children) == 1:
            self.ic_return("%s__leave" % node.children[0].mangled)
        else:
            self.ic_leave("__fastcall__")

    def visit_UNTIL_DO(self, node):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        continue_loop = backend.tmp_label()

        if node.token == "UNTIL_DO":
            self.ic_jump(continue_loop)

        self.ic_label(loop_label)
        self.LOOPS.append(("DO", end_loop, continue_loop))  # Saves which labels to jump upon EXIT or CONTINUE

        if len(node.children) > 1:
            yield node.children[1]

        self.ic_label(continue_loop)
        yield node.children[0]  # Condition
        self.ic_jzero(node.children[0].type_, node.children[0].t, loop_label)
        self.ic_label(end_loop)
        self.LOOPS.pop()
        # del loop_label, end_loop, continue_loop

    def visit_WHILE(self, node):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        self.LOOPS.append(("WHILE", end_loop, loop_label))  # Saves which labels to jump upon EXIT or CONTINUE

        self.ic_label(loop_label)
        yield node.children[0]
        self.ic_jzero(node.children[0].type_, node.children[0].t, end_loop)

        if len(node.children) > 1:
            yield node.children[1]

        self.ic_jump(loop_label)
        self.ic_label(end_loop)
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
        self.ic_param(node.children[0].type_, node.children[0].t)
        yield node.children[1]
        self.ic_fparam(node.children[1].type_, node.children[1].t)
        self.runtime_call(RuntimeLabel.PLOT, 0)
        self.HAS_ATTR = TMP_HAS_ATTR is not None
        self.norm_attr()

    def visit_DRAW(self, node):
        TMP_HAS_ATTR = self.check_attr(node, 2)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.ic_param(node.children[0].type_, node.children[0].t)
        yield node.children[1]
        self.ic_fparam(node.children[1].type_, node.children[1].t)
        self.runtime_call(RuntimeLabel.DRAW, 0)
        self.HAS_ATTR = TMP_HAS_ATTR is not None
        self.norm_attr()

    def visit_DRAW3(self, node):
        TMP_HAS_ATTR = self.check_attr(node, 3)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.ic_param(node.children[0].type_, node.children[0].t)
        yield node.children[1]
        self.ic_param(node.children[1].type_, node.children[1].t)
        yield node.children[2]
        self.ic_fparam(node.children[2].type_, node.children[2].t)
        self.runtime_call(RuntimeLabel.DRAW3, 0)
        self.HAS_ATTR = TMP_HAS_ATTR is not None
        self.norm_attr()

    def visit_CIRCLE(self, node):
        TMP_HAS_ATTR = self.check_attr(node, 3)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.ic_param(node.children[0].type_, node.children[0].t)
        yield node.children[1]
        self.ic_param(node.children[1].type_, node.children[1].t)
        yield node.children[2]
        self.ic_fparam(node.children[2].type_, node.children[2].t)
        self.runtime_call(RuntimeLabel.CIRCLE, 0)
        self.HAS_ATTR = TMP_HAS_ATTR is not None
        self.norm_attr()

    # endregion

    # region [I/O Statements]
    # -----------------------------------------------------------------------------------------------------
    # PRINT, LOAD, SAVE and I/O statements
    # -----------------------------------------------------------------------------------------------------
    def visit_OUT(self, node):
        yield node.children[0]
        yield node.children[1]
        self.ic_out(node.children[0].t, node.children[1].t)

    def visit_PRINT(self, node):
        for i in node.children:
            yield i

            # Print subcommands (AT, OVER, INK, etc... must be skipped here)
            if (
                i.token
                in (
                    "PRINT_TAB",
                    "PRINT_AT",
                    "PRINT_COMMA",
                )
                + self.ATTR_TMP
            ):
                continue

            self.ic_fparam(i.type_, i.t)
            label = {
                "i8": RuntimeLabel.PRINTI8,
                "u8": RuntimeLabel.PRINTU8,
                "i16": RuntimeLabel.PRINTI16,
                "u16": RuntimeLabel.PRINTU16,
                "i32": RuntimeLabel.PRINTI32,
                "u32": RuntimeLabel.PRINTU32,
                "f16": RuntimeLabel.PRINTF16,
                "f": RuntimeLabel.PRINTF,
                "str": RuntimeLabel.PRINTSTR,
            }[self.TSUFFIX(i.type_)]
            self.runtime_call(label, 0)

        for i in node.children:
            if i.token in self.ATTR_TMP or self.has_control_chars(i):
                self.HAS_ATTR = True
                break

        if node.eol:
            if self.HAS_ATTR:
                self.runtime_call(RuntimeLabel.PRINT_EOL_ATTR, 0)
                self.HAS_ATTR = False
            else:
                self.runtime_call(RuntimeLabel.PRINT_EOL, 0)
        else:
            self.norm_attr()

    def visit_PRINT_AT(self, node):
        yield node.children[0]
        self.ic_param(TYPE.ubyte, node.children[0].t)
        yield node.children[1]
        self.ic_fparam(TYPE.ubyte, node.children[1].t)
        self.runtime_call(RuntimeLabel.PRINT_AT, 0)  # Procedure call. Discard return

    def visit_PRINT_TAB(self, node):
        yield node.children[0]
        self.ic_fparam(TYPE.ubyte, node.children[0].t)
        self.runtime_call(RuntimeLabel.PRINT_TAB, 0)

    def visit_PRINT_COMMA(self, node):
        self.runtime_call(RuntimeLabel.PRINT_COMMA, 0)

    def visit_LOAD(self, node):
        yield node.children[0]
        self.ic_param(TYPE.string, node.children[0].t)
        yield node.children[1]
        self.ic_param(gl.PTR_TYPE, node.children[1].t)
        yield node.children[2]
        self.ic_param(gl.PTR_TYPE, node.children[2].t)

        self.ic_param(TYPE.ubyte, int(node.token == "LOAD"))
        self.runtime_call(RuntimeLabel.LOAD_CODE, 0)

    def visit_SAVE(self, node):
        yield (node.children[0])
        self.ic_param(TYPE.string, node.children[0].t)
        yield (node.children[1])
        self.ic_param(gl.PTR_TYPE, node.children[1].t)
        yield node.children[2]
        self.ic_param(gl.PTR_TYPE, node.children[2].t)
        self.runtime_call(RuntimeLabel.SAVE_CODE, 0)

    def visit_VERIFY(self, node):
        return self.visit_LOAD(node)

    def visit_BORDER(self, node):
        yield node.children[0]
        self.ic_fparam(TYPE.ubyte, node.children[0].t)
        self.runtime_call(RuntimeLabel.BORDER, 0)

    def visit_BEEP(self, node):
        if node.children[0].token == node.children[1].token == "NUMBER":  # BEEP <const>, <const>
            DE, HL = src.arch.zx48k.beep.getDEHL(float(node.children[0].t), float(node.children[1].t))
            self.ic_param(TYPE.uinteger, HL)
            self.ic_fparam(TYPE.uinteger, DE)
            self.runtime_call(RuntimeLabel.BEEPER, 0)  # Procedure call. Discard return
        else:
            yield node.children[1]
            self.ic_param(TYPE.float, node.children[1].t)
            yield node.children[0]
            self.ic_fparam(TYPE.float, node.children[0].t)
            self.runtime_call(RuntimeLabel.BEEP, 0)

    def visit_PAUSE(self, node):
        yield node.children[0]
        self.ic_fparam(node.children[0].type_, node.children[0].t)
        self.runtime_call(RuntimeLabel.PAUSE, 0)

    # endregion

    # region [ATTR Sentences]
    # -----------------------------------------------------------------------
    # ATTR sentences: INK, PAPER, BRIGHT, FLASH, INVERSE, OVER, ITALIC, BOLD
    # -----------------------------------------------------------------------
    def visit_ATTR_sentence(self, node):
        yield node.children[0]
        self.ic_fparam(TYPE.ubyte, node.children[0].t)

        label = {
            "INK": RuntimeLabel.INK,
            "PAPER": RuntimeLabel.PAPER,
            "FLASH": RuntimeLabel.FLASH,
            "BRIGHT": RuntimeLabel.BRIGHT,
            "INVERSE": RuntimeLabel.INVERSE,
            "OVER": RuntimeLabel.OVER,
            "BOLD": RuntimeLabel.BOLD,
            "ITALIC": RuntimeLabel.ITALIC,
        }[node.token]

        self.runtime_call(label, 0)
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
        EOL = "\n"
        self.ic_inline(f'#line {node.lineno} "{node.filename}"')
        self.ic_inline(node.asm)
        self.ic_inline(f'#line {node.lineno + len(node.asm.split(EOL))} "{node.filename}"')

    # endregion

    # region [Helpers]
    # --------------------------------------
    # Helpers
    # --------------------------------------
    def emit_var_assign(self, var, t):
        """Emits code for storing a value into a variable
        :param var: variable (node) to be updated
        :param t: the value to emmit (e.g. a _label, a const, a tN...)
        """
        p = "*" if var.byref else ""  # Indirection prefix
        if self.O_LEVEL > 1 and not var.accessed:
            return

        if not var.type_.is_basic:
            raise NotImplementedError()

        if var.scope == SCOPE.global_:
            self.ic_store(var.type_, var.mangled, t)
        elif var.scope == SCOPE.parameter:
            self.ic_pstore(var.type_, p + str(var.offset), t)
        elif var.scope == SCOPE.local:
            if var.alias is not None and var.alias.class_ == CLASS.array:
                var.offset -= 1 + 2 * var.alias.count
            self.ic_pstore(var.type_, p + str(-var.offset), t)

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
        """Returns the label for the given loop type which
        exits the loop. loop_type must be one of 'FOR', 'WHILE', 'DO'
        """
        for i in range(len(self.LOOPS) - 1, -1, -1):
            if loop_type == self.LOOPS[i][0]:
                return self.LOOPS[i][1]

        raise InvalidLoopError(loop_type)

    def loop_cont_label(self, loop_type):
        """Returns the label for the given loop type which
        continues the loop. loop_type must be one of 'FOR', 'WHILE', 'DO'
        """
        for i in range(len(self.LOOPS) - 1, -1, -1):
            if loop_type == self.LOOPS[i][0]:
                return self.LOOPS[i][2]

        raise InvalidLoopError(loop_type)

    @classmethod
    def default_value(cls, type_, expr):  # TODO: This function must be moved to api.xx
        """Returns a list of bytes (as hexadecimal 2 char string)"""
        assert isinstance(type_, symbols.TYPE)
        assert type_.is_basic
        assert check.is_static(expr)

        if isinstance(expr, (symbols.CONST, symbols.VAR)):  # a constant expression like @label + 1
            if type_ in (cls.TYPE(TYPE.float), cls.TYPE(TYPE.string)):
                error(expr.lineno, "Can't convert non-numeric value to {0} at compile time".format(type_.name))
                return ["<ERROR>"]

            val = Translator.traverse_const(expr)
            if type_.size == 1:  # U/byte
                if expr.type_.size != 1:
                    return ["#({0}) & 0xFF".format(val)]
                else:
                    return ["#{0}".format(val)]

            if type_.size == 2:  # U/integer
                if expr.type_.size != 2:
                    return ["##({0}) & 0xFFFF".format(val)]
                else:
                    return ["##{0}".format(val)]

            if type_ == cls.TYPE(TYPE.fixed):
                return ["0000", "##({0}) & 0xFFFF".format(val)]

            # U/Long
            return ["##({0}) & 0xFFFF".format(val), "##(({0}) >> 16) & 0xFFFF".format(val)]

        if type_ == cls.TYPE(TYPE.float):
            C, DE, HL = _float(expr.value)
            C = C[:-1]  # Remove 'h' suffix
            if len(C) > 2:
                C = C[-2:]

            DE = DE[:-1]  # Remove 'h' suffix
            if len(DE) > 4:
                DE = DE[-4:]
            elif len(DE) < 3:
                DE = "00" + DE

            HL = HL[:-1]  # Remove 'h' suffix
            if len(HL) > 4:
                HL = HL[-4:]
            elif len(HL) < 3:
                HL = "00" + HL

            return [C, DE[-2:], DE[:-2], HL[-2:], HL[:-2]]

        if type_ == cls.TYPE(TYPE.fixed):
            value = 0xFFFFFFFF & int(expr.value * 2**16)
        else:
            value = int(expr.value)

        result = [value, value >> 8, value >> 16, value >> 24]
        result = ["%02X" % (v & 0xFF) for v in result]
        return result[: type_.size]

    @staticmethod
    def array_default_value(type_, values):
        """Returns a list of bytes (as hexadecimal 2 char string)
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
        """Returns true if the passed token is an unknown string
        or a constant string having control chars (inverse, etc
        """
        if not hasattr(i, "type_"):
            return False

        if i.type_ != Type.string:
            return False

        if i.token in ("VAR", "PARAMDECL"):
            return True  # We don't know what an alphanumeric variable will hold

        if i.token == "STRING":
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
    """Var Translator
    This translator emits memory var space
    """

    def visit_LABEL(self, node):
        self.ic_label(node.mangled)
        for tmp in node.aliased_by:
            self.ic_label(tmp.mangled)

    def visit_VARDECL(self, node):
        entry = node.entry
        if not entry.accessed:
            src.api.errmsg.warning_not_used(entry.lineno, entry.name)
            if self.O_LEVEL > 1:  # HINT: Unused vars not compiled
                return

        if entry.addr is not None:
            addr = self.traverse_const(entry.addr) if isinstance(entry.addr, symbols.SYMBOL) else entry.addr
            self.ic_deflabel(entry.mangled, addr)
            for entry in entry.aliased_by:
                self.ic_deflabel(entry.mangled, entry.addr)
        elif entry.alias is None:
            for alias in entry.aliased_by:
                self.ic_label(alias.mangled)
            if entry.default_value is None:
                self.ic_var(entry.mangled, entry.size)
            else:
                if isinstance(entry.default_value, symbols.CONST) and entry.default_value.token == "CONST":
                    self.ic_varx(node.mangled, node.type_, [self.traverse_const(entry.default_value)])
                else:
                    self.ic_vard(node.mangled, Translator.default_value(node.type_, entry.default_value))

    def visit_ARRAYDECL(self, node):
        entry = node.entry
        assert entry.default_value is None or entry.addr is None, "Cannot use address and default_value at once"

        if not entry.accessed:
            src.api.errmsg.warning_not_used(entry.lineno, entry.name, fname=entry.filename)
            if self.O_LEVEL > 1:
                return

        bound_ptrs = []  # Bound tables pointers (empty if not used)
        lbound_label = entry.mangled + ".__LBOUND__"
        ubound_label = entry.mangled + ".__UBOUND__"

        if entry.lbound_used or entry.ubound_used:
            bound_ptrs = ["0", "0"]  # NULL by default
            if entry.lbound_used:
                bound_ptrs[0] = lbound_label
            if entry.ubound_used:
                bound_ptrs[1] = ubound_label

        data_label = entry.data_label
        idx_table_label = backend.tmp_label()
        l = ["%04X" % (len(node.bounds) - 1)]  # Number of dimensions - 1

        for bound in node.bounds[1:]:
            l.append("%04X" % (bound.upper - bound.lower + 1))

        l.append("%02X" % node.type_.size)
        arr_data = []

        if entry.addr:
            addr = self.traverse_const(entry.addr) if isinstance(entry.addr, symbols.SYMBOL) else entry.addr
            self.ic_deflabel(data_label, "%s" % addr)
        else:
            if entry.default_value is not None:
                arr_data = Translator.array_default_value(node.type_, entry.default_value)
            else:
                arr_data = ["00"] * node.size

        for alias in entry.aliased_by:
            offset = 1 + 2 * TYPE.size(gl.PTR_TYPE) + alias.offset  # TODO: Generalize for multi-arch
            self.ic_deflabel(alias.mangled, "%s + %i" % (entry.mangled, offset))

        self.ic_varx(node.mangled, gl.PTR_TYPE, [idx_table_label])

        if entry.addr:
            self.ic_varx(entry.data_ptr_label, gl.PTR_TYPE, [self.traverse_const(entry.addr)])
            if bound_ptrs:
                self.ic_data(gl.PTR_TYPE, bound_ptrs)
        else:
            self.ic_varx(entry.data_ptr_label, gl.PTR_TYPE, [data_label])
            if bound_ptrs:
                self.ic_data(gl.PTR_TYPE, bound_ptrs)
            self.ic_vard(data_label, arr_data)

        self.ic_vard(idx_table_label, l)

        if entry.lbound_used:
            l = ["%04X" % bound.lower for bound in node.bounds]
            self.ic_vard(lbound_label, l)

        if entry.ubound_used:
            l = ["%04X" % bound.upper for bound in node.bounds]
            self.ic_vard(ubound_label, l)


class UnaryOpTranslator(TranslatorVisitor):
    """UNARY sub-visitor. E.g. -a or bNot pi"""

    def visit_MINUS(self, node):
        yield node.operand
        self.ic_neg(node.type_, node.t, node.operand.t)

    def visit_NOT(self, node):
        yield node.operand
        self.ic_not(node.operand.type_, node.t, node.operand.t)

    def visit_BNOT(self, node):
        yield node.operand
        self.ic_bnot(node.operand.type_, node.t, node.operand.t)

    def visit_ADDRESS(self, node):
        scope = node.operand.scope
        if node.operand.token == "ARRAYACCESS":
            yield node.operand
            # Address of an array element.
            if scope == SCOPE.global_:
                self.ic_aaddr(node.t, node.operand.entry.mangled)
            elif scope == SCOPE.parameter:
                self.ic_paaddr(node.t, "*{}".format(node.operand.entry.offset))
            elif scope == SCOPE.local:
                self.ic_paaddr(node.t, -node.operand.entry.offset)
        else:  # It's a scalar variable
            if scope == SCOPE.global_:
                self.ic_load(node.type_, node.t, "#" + node.operand.t)
            elif scope == SCOPE.parameter:
                self.ic_paddr(node.operand.offset + node.operand.type_.size % 2, node.t)
            elif scope == SCOPE.local:
                self.ic_paddr(-node.operand.offset, node.t)


class BuiltinTranslator(TranslatorVisitor):
    """BUILTIN functions visitor. Eg. LEN(a$) or SIN(x)"""

    REQUIRES = backend.REQUIRES

    # region STRING Functions
    def visit_INKEY(self, node):
        self.runtime_call(RuntimeLabel.INKEY, Type.string.size)

    def visit_IN(self, node):
        self.ic_in(node.children[0].t)

    def visit_CODE(self, node):
        self.ic_fparam(gl.PTR_TYPE, node.operand.t)
        if node.operand.token not in ("STRING", "VAR", "PARAMDECL") and node.operand.t != "_":
            self.ic_fparam(TYPE.ubyte, 1)  # If the argument is not a variable, it must be freed
        else:
            self.ic_fparam(TYPE.ubyte, 0)

        self.runtime_call(RuntimeLabel.ASC, Type.ubyte.size)  # Expect a char code

    def visit_CHR(self, node):
        self.ic_fparam(gl.STR_INDEX_TYPE, len(node.operand))  # Number of args
        self.runtime_call(RuntimeLabel.CHR, node.size)

    def visit_STR(self, node):
        self.ic_fparam(TYPE.float, node.children[0].t)
        self.runtime_call(RuntimeLabel.STR_FAST, node.type_.size)

    def visit_LEN(self, node):
        self.ic_lenstr(node.t, node.operand.t)

    def visit_VAL(self, node):
        self.ic_fparam(gl.PTR_TYPE, node.operand.t)
        if node.operand.token not in ("STRING", "VAR", "PARAMDECL") and node.operand.t != "_":
            self.ic_fparam(TYPE.ubyte, 1)  # If the argument is not a variable, it must be freed
        else:
            self.ic_fparam(TYPE.ubyte, 0)

        self.runtime_call(RuntimeLabel.VAL, node.type_.size)

    # endregion

    def visit_ABS(self, node):
        self.ic_abs(node.children[0].type_, node.t, node.children[0].t)

    def visit_RND(self, node):  # A special "ZEROARY" function with no parameters
        self.runtime_call(RuntimeLabel.RND, Type.float_.size)

    def visit_PEEK(self, node):
        self.ic_load(node.type_, node.t, "*" + str(node.children[0].t))

    # region MATH Functions
    def visit_SIN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.SIN, node.size)

    def visit_COS(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.COS, node.size)

    def visit_TAN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.TAN, node.size)

    def visit_ASN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.ASN, node.size)

    def visit_ACS(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.ACS, node.size)

    def visit_ATN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.ATN, node.size)

    def visit_EXP(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.EXP, node.size)

    def visit_LN(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.LN, node.size)

    def visit_SGN(self, node):
        s = self.TSUFFIX(node.operand.type_)
        self.ic_fparam(node.operand.type_, node.operand.t)

        label = {
            "i8": RuntimeLabel.SGNI8,
            "u8": RuntimeLabel.SGNU8,
            "i16": RuntimeLabel.SGNI16,
            "u16": RuntimeLabel.SGNU16,
            "i32": RuntimeLabel.SGNI32,
            "u32": RuntimeLabel.SGNU32,
            "f16": RuntimeLabel.SGNF16,
            "f": RuntimeLabel.SGNF,
        }[s]
        self.runtime_call(label, node.size)

    def visit_SQR(self, node):
        self.ic_fparam(node.operand.type_, node.operand.t)
        self.runtime_call(RuntimeLabel.SQR, node.size)

    # endregion

    def visit_LBOUND(self, node):
        yield node.operands[1]
        self.ic_param(gl.BOUND_TYPE, node.operands[1].t)
        entry = node.operands[0]
        if entry.scope == SCOPE.global_:
            self.ic_fparam(gl.PTR_TYPE, "#{}".format(entry.mangled))
        elif entry.scope == SCOPE.parameter:
            self.ic_pload(gl.PTR_TYPE, entry.t, entry.offset)
            t1 = optemps.new_t()
            self.ic_fparam(gl.PTR_TYPE, t1)
        elif entry.scope == SCOPE.local:
            self.ic_paddr(-entry.offset, entry.t)
            t1 = optemps.new_t()
            self.ic_fparam(gl.PTR_TYPE, t1)
        self.runtime_call(RuntimeLabel.LBOUND, self.TYPE(gl.BOUND_TYPE).size)

    def visit_UBOUND(self, node):
        yield node.operands[1]
        self.ic_param(gl.BOUND_TYPE, node.operands[1].t)
        entry = node.operands[0]
        if entry.scope == SCOPE.global_:
            self.ic_fparam(gl.PTR_TYPE, "#{}".format(entry.mangled))
        elif entry.scope == SCOPE.parameter:
            self.ic_pload(gl.PTR_TYPE, entry.t, entry.offset)
            t1 = optemps.new_t()
            self.ic_fparam(gl.PTR_TYPE, t1)
        elif entry.scope == SCOPE.local:
            self.ic_paddr(-entry.offset, entry.t)
            t1 = optemps.new_t()
            self.ic_fparam(gl.PTR_TYPE, t1)
        self.runtime_call(RuntimeLabel.UBOUND, self.TYPE(gl.BOUND_TYPE).size)

    def visit_USR_STR(self, node):
        # USR ADDR
        self.ic_fparam(TYPE.string, node.children[0].t)
        self.runtime_call(RuntimeLabel.USR_STR, node.type_.size)

    def visit_USR(self, node):
        """Machine code call from basic"""
        self.ic_fparam(gl.PTR_TYPE, node.children[0].t)
        self.runtime_call(RuntimeLabel.USR, node.type_.size)


class FunctionTranslator(Translator):
    REQUIRES = backend.REQUIRES

    def __init__(self, function_list):
        if function_list is None:
            function_list = []
        super().__init__()

        assert isinstance(function_list, list)
        for x in function_list:
            assert isinstance(x, symbols.FUNCTION)
        self.functions = function_list

    def _local_array_load(self, scope, local_var):
        t2 = optemps.new_t()
        if scope == SCOPE.parameter:
            self.ic_pload(gl.PTR_TYPE, t2, "%i" % (local_var.offset - self.TYPE(gl.PTR_TYPE).size))
        elif scope == SCOPE.local:
            self.ic_pload(gl.PTR_TYPE, t2, "%i" % -(local_var.offset - self.TYPE(gl.PTR_TYPE).size))
        self.ic_fparam(gl.PTR_TYPE, t2)

    def start(self):
        while self.functions:
            f = self.functions.pop(0)
            __DEBUG__("Translating function " + f.__repr__())
            self.visit(f)

    def visit_FUNCTION(self, node):
        bound_tables = []

        self.ic_label(node.mangled)
        if node.convention == CONVENTION.fastcall:
            self.ic_enter("__fastcall__")
        else:
            self.ic_enter(node.locals_size)

        for local_var in node.local_symbol_table.values():
            if not local_var.accessed:  # HINT: This should never happens as values() is already filtered
                src.api.errmsg.warning_not_used(local_var.lineno, local_var.name)
                # HINT: Cannot optimize local variables now, since the offsets are already calculated
                # if self.O_LEVEL > 1:
                #    return

            if local_var.class_ == CLASS.array and local_var.scope == SCOPE.local:
                bound_ptrs = []  # Bound tables pointers (empty if not used)
                lbound_label = local_var.mangled + ".__LBOUND__"
                ubound_label = local_var.mangled + ".__UBOUND__"

                if local_var.lbound_used or local_var.ubound_used:
                    bound_ptrs = ["0", "0"]  # NULL by default
                    if local_var.lbound_used:
                        bound_ptrs[0] = lbound_label
                    if local_var.ubound_used:
                        bound_ptrs[1] = ubound_label

                if bound_ptrs:
                    zxbpp.ID_TABLE.define("__ZXB_USE_LOCAL_ARRAY_WITH_BOUNDS__", lineno=0)

                if local_var.lbound_used:
                    l = ["%04X" % bound.lower for bound in local_var.bounds]
                    bound_tables.append(LabelledData(lbound_label, l))

                if local_var.ubound_used:
                    l = ["%04X" % bound.upper for bound in local_var.bounds]
                    bound_tables.append(LabelledData(ubound_label, l))

                l = [len(local_var.bounds) - 1] + [x.count for x in local_var.bounds[1:]]  # TODO Check this
                q = []
                for x in l:
                    q.append("%02X" % (x & 0xFF))
                    q.append("%02X" % ((x & 0xFF) >> 8))

                q.append("%02X" % local_var.type_.size)
                r = []
                if local_var.default_value is not None:
                    r.extend(self.array_default_value(local_var.type_, local_var.default_value))
                self.ic_larrd(local_var.offset, q, local_var.size, r, bound_ptrs)  # Initializes array bounds
            elif local_var.class_ == CLASS.const or local_var.scope == SCOPE.parameter:
                continue
            else:  # Local vars always defaults to 0, so if 0 we do nothing
                if local_var.default_value is not None and local_var.default_value != 0:
                    if isinstance(local_var.default_value, symbols.CONST) and local_var.default_value.token == "CONST":
                        self.ic_lvarx(local_var.type_, local_var.offset, [self.traverse_const(local_var.default_value)])
                    else:
                        q = self.default_value(local_var.type_, local_var.default_value)
                        self.ic_lvard(local_var.offset, q)

        for i in node.body:
            yield i

        self.norm_attr()
        self.ic_label("%s__leave" % node.mangled)

        # Now free any local string from memory.
        preserve_hl = False
        if node.convention == CONVENTION.stdcall:
            for local_var in node.local_symbol_table.values():
                scope = local_var.scope
                if local_var.type_ == self.TYPE(TYPE.string):  # Only if it's string we free it
                    if local_var.class_ != CLASS.array:  # Ok just free it
                        if scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref):
                            if not preserve_hl:
                                preserve_hl = True
                                self.ic_exchg()

                            offset = -local_var.offset if scope == SCOPE.local else local_var.offset
                            self.ic_fpload(TYPE.string, local_var.t, offset)
                            self.runtime_call(RuntimeLabel.MEM_FREE, 0)
                    elif local_var.class_ == CLASS.const:
                        continue
                    else:  # This is an array of strings, we must free it unless it's a by_ref array
                        if scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref):
                            if not preserve_hl:
                                preserve_hl = True
                                self.ic_exchg()

                            self.ic_param(gl.BOUND_TYPE, local_var.count)
                            self._local_array_load(scope, local_var)
                            self.runtime_call(RuntimeLabel.ARRAYSTR_FREE_MEM, 0)

                if (
                    local_var.class_ == CLASS.array
                    and local_var.type_ != self.TYPE(TYPE.string)
                    and (scope == SCOPE.local or (scope == SCOPE.parameter and not local_var.byref))
                ):
                    if not preserve_hl:
                        preserve_hl = True
                        self.ic_exchg()

                    self._local_array_load(scope, local_var)
                    self.runtime_call(RuntimeLabel.MEM_FREE, 0)

        if preserve_hl:
            self.ic_exchg()

        if node.convention == CONVENTION.fastcall:
            self.ic_leave(CONVENTION.to_string(node.convention))
        else:
            self.ic_leave(node.params.size)

        for bound_table in bound_tables:
            self.ic_vard(bound_table.label, bound_table.data)

    def visit_FUNCDECL(self, node):
        """Nested scope functions"""
        self.functions.append(node.entry)
