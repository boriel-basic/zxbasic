#!/usr/bin/env python
# -*- coding: utf-8 -*-

from collections import namedtuple

import src.api.check as check
import src.api.errmsg
import src.api.global_ as gl
import src.api.tmp_labels
from src.api.config import OPTIONS
from src.api.constants import CLASS, CONVENTION, SCOPE, TYPE
from src.api.debug import __DEBUG__
from src.api.errmsg import error
from src.api.exception import (
    InternalError,
    InvalidBuiltinFunctionError,
    InvalidLoopError,
    InvalidOperatorError,
)
from src.api.global_ import optemps
from src.arch.z80.backend._float import _float
from src.arch.z80.backend.runtime import Labels as RuntimeLabel
from src.arch.z80.visitor.builtin_translator import BuiltinTranslator
from src.arch.z80.visitor.translator_visitor import JumpTable, TranslatorVisitor
from src.arch.z80.visitor.unary_op_translator import UnaryOpTranslator
from src.symbols import sym as symbols
from src.symbols.id_ import ref
from src.symbols.type_ import Type

__all__ = ("Translator",)

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
        assert node.children[0].token == "VAR"
        if self.O_LEVEL < 2 or node.children[0].accessed or node.children[1].token == "CONSTEXPR":
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

    def visit_CONST(self, node):
        yield node.symbol

    def visit_VAR(self, node):
        __DEBUG__(
            "{}: VAR {}:{} Scope: {} Class: {}".format(
                node.lineno, node.name, node.type_, SCOPE.to_string(node.scope), CLASS.to_string(node.class_)
            )
        )
        scope = node.scope

        if node.t == node.mangled and scope == SCOPE.global_:
            return

        p = "*" if node.byref else ""  # Indirection prefix

        if scope == SCOPE.parameter:
            self.ic_pload(node.type_, node.t, p + str(node.offset))
        elif scope == SCOPE.local:
            offset = node.offset
            self.ic_pload(node.type_, node.t, p + str(-offset))

    def visit_CONSTEXPR(self, node):
        yield node.t

    def visit_VARARRAY(self, node):
        pass

    def visit_PARAMDECL(self, node):
        assert node.scope == SCOPE.parameter
        self.visit_VAR(node)

    def visit_UNARY(self, node):
        uvisitor = UnaryOpTranslator(self.backend)
        att = "visit_{}".format(node.operator)
        if hasattr(uvisitor, att):
            yield getattr(uvisitor, att)(node)
            return

        raise InvalidOperatorError(node.operator)

    def visit_BUILTIN(self, node):
        yield node.operand
        bvisitor = BuiltinTranslator(self.backend)
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
            if node.value.token == "VAR" and node.type_.is_dynamic and node.value.t[0] == "$":
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

    def _emit_arraycopy_child(self, child: symbols.ID):
        assert child.token == "VARARRAY"
        child_ref = child.ref
        assert isinstance(child_ref, ref.ArrayRef)

        scope = child.scope
        if scope == SCOPE.global_:
            t = f"#{child_ref.data_label}"
        elif scope == SCOPE.parameter:
            t = optemps.new_t()
            self.ic_pload(gl.PTR_TYPE, t, f"{child_ref.offset - self.TYPE(gl.PTR_TYPE).size}")
        else:
            t = optemps.new_t()
            self.ic_pload(gl.PTR_TYPE, t, "%i" % -(child.offset - self.TYPE(gl.PTR_TYPE).size))
        return t

    def visit_ARRAYCOPY(self, node):
        t_source = node.args[1]
        t_dest = node.args[0]
        t = optemps.new_t()

        if t_source.type_ != Type.string:
            t1 = self._emit_arraycopy_child(t_dest)
            t2 = self._emit_arraycopy_child(t_source)
            self.ic_load(gl.BOUND_TYPE, t, "%i" % t_source.size)
            self.ic_memcopy(t1, t2, t)
        else:
            t2 = self._emit_arraycopy_child(t_dest)
            if t_dest.scope == SCOPE.global_:
                self.ic_load(gl.PTR_TYPE, optemps.new_t(), t2)

            t1 = self._emit_arraycopy_child(t_source)
            if t_source.scope == SCOPE.global_:
                self.ic_load(gl.PTR_TYPE, optemps.new_t(), t1)

            self.ic_load(gl.BOUND_TYPE, t, "%i" % t_source.count)
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

        if node.string.token == "VAR" and node.string.mangled[0] == "_" or node.string.token == "STRING":
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
        loop_label = src.api.tmp_labels.tmp_label()
        end_loop = src.api.tmp_labels.tmp_label()
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
        loop_label = src.api.tmp_labels.tmp_label()
        end_loop = src.api.tmp_labels.tmp_label()
        continue_loop = src.api.tmp_labels.tmp_label()

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
        loop_label_start = src.api.tmp_labels.tmp_label()
        loop_label_gt = src.api.tmp_labels.tmp_label()
        end_loop = src.api.tmp_labels.tmp_label()
        loop_body = src.api.tmp_labels.tmp_label()
        loop_continue = src.api.tmp_labels.tmp_label()
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
        table_label = src.api.tmp_labels.tmp_label()
        self.ic_param(gl.PTR_TYPE, "#" + table_label)
        yield node.children[0]
        self.ic_fparam(node.children[0].type_, node.children[0].t)
        self.runtime_call(RuntimeLabel.ON_GOTO, 0)
        self.JUMP_TABLES.append(JumpTable(table_label, node.children[1:]))

    def visit_ON_GOSUB(self, node):
        table_label = src.api.tmp_labels.tmp_label()
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
        if_label_else = src.api.tmp_labels.tmp_label()
        if_label_endif = src.api.tmp_labels.tmp_label()

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
        loop_label = src.api.tmp_labels.tmp_label()
        end_loop = src.api.tmp_labels.tmp_label()
        continue_loop = src.api.tmp_labels.tmp_label()

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
        loop_label = src.api.tmp_labels.tmp_label()
        end_loop = src.api.tmp_labels.tmp_label()
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
        self.norm_attr()
        TMP_HAS_ATTR = self.check_attr(node, 2)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.ic_param(node.children[0].type_, node.children[0].t)
        yield node.children[1]
        self.ic_fparam(node.children[1].type_, node.children[1].t)
        self.runtime_call(RuntimeLabel.PLOT, 0)
        self.HAS_ATTR = TMP_HAS_ATTR is not None

    def visit_DRAW(self, node):
        self.norm_attr()
        TMP_HAS_ATTR = self.check_attr(node, 2)
        yield TMP_HAS_ATTR
        yield node.children[0]
        self.ic_param(node.children[0].type_, node.children[0].t)
        yield node.children[1]
        self.ic_fparam(node.children[1].type_, node.children[1].t)
        self.runtime_call(RuntimeLabel.DRAW, 0)
        self.HAS_ATTR = TMP_HAS_ATTR is not None

    def visit_DRAW3(self, node):
        self.norm_attr()
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

    def visit_CIRCLE(self, node):
        self.norm_attr()
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
        self.norm_attr()
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

        if node.eol:
            self.runtime_call(RuntimeLabel.PRINT_EOL, 0)

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
    def default_value(cls, type_: symbols.TYPE, expr) -> list[str]:  # TODO: This function must be moved to api.xx
        """Returns a list of bytes (as hexadecimal 2 char string)"""
        assert isinstance(type_, symbols.TYPE)
        assert type_.is_basic
        assert check.is_static(expr)

        if expr.token in ("CONSTEXPR", "CONST"):  # a constant expression like @label + 1
            if type_ in (cls.TYPE(TYPE.float), cls.TYPE(TYPE.string)):
                error(expr.lineno, f"Can't convert non-numeric value to {type_.name} at compile time")
                return ["<ERROR>"]  # dummy placeholder so the compilation continues

            val = Translator.traverse_const(expr)
            if type_.size == 1:  # U/byte
                if expr.type_.size != 1:
                    return [f"#({val}) & 0xFF"]
                else:
                    return [f"#{val}"]

            if type_.size == 2:  # U/integer
                if expr.type_.size != 2:
                    return [f"##({val}) & 0xFFFF"]
                else:
                    return [f"##{val}"]

            if type_ == cls.TYPE(TYPE.fixed):
                return ["0000", f"##({val}) & 0xFFFF"]

            # U/Long
            return [f"##({val}) & 0xFFFF", f"##(({val}) >> 16) & 0xFFFF"]

        if type_ == cls.TYPE(TYPE.float):
            C, DE, HL = _float(expr.value)
            C = C[:-1]  # Remove 'h' suffix
            C = C[-2:]

            DE = DE[:-1]  # Remove 'h' suffix
            DE = ("00" + DE)[-4:]

            HL = HL[:-1]  # Remove 'h' suffix
            HL = ("00" + HL)[-4:]

            return [C, DE[-2:], DE[:-2], HL[-2:], HL[:-2]]

        if type_ == cls.TYPE(TYPE.fixed):
            value = 0xFFFFFFFF & int(expr.value * 2**16)
        else:
            value = int(expr.value)

        values = [value, value >> 8, value >> 16, value >> 24]
        result = ["%02X" % (v & 0xFF) for v in values]
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

        if i.token == "VAR":
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
