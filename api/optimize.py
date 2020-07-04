#!/usr/bin/env python
# -*- coding: utf-8 -*-

from ast_ import NodeVisitor
from .config import OPTIONS
import api.errmsg
from api.errmsg import warning
import api.check as chk
from api.constants import TYPE, SCOPE, CLASS
import api.global_ as gl
import symbols
import types
from api.debug import __DEBUG__
from api.errmsg import warning_not_used
import api.utils
import api.symboltable


class ToVisit(object):
    """ Used just to signal an object to be
    traversed.
    """
    def __init__(self, obj):
        self.obj = obj


class OptimizerVisitor(NodeVisitor):
    """ Implements some optimizations
    """
    NOP = symbols.NOP()  # Return this for "erased" nodes

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
        if self.O_LEVEL < 1:  # Optimize only if O1 or above
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
        elif node.operand.offset is not None:  # A constant access
            if node.operand.scope == SCOPE.global_:  # Calculate offset if global variable
                node = symbols.BINARY.make_node(
                    'PLUS',
                    symbols.UNARY('ADDRESS', node.operand.entry, node.lineno, type_=self.TYPE(gl.PTR_TYPE)),
                    symbols.NUMBER(node.operand.offset, lineno=node.operand.lineno, type_=self.TYPE(gl.PTR_TYPE)),
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
            yield symbols.STRING(''.join(
                chr(api.utils.get_final_value(x.value) & 0xFF) for x in node.operand), node.lineno)
        else:
            yield node

    def visit_CONST(self, node):
        if chk.is_number(node.expr) or chk.is_const(node.expr):
            yield node.expr
        else:
            yield node

    def visit_FUNCCALL(self, node):
        node.args = (yield self.generic_visit(node.args))  # Avoid infinite recursion not visiting node.entry
        self._check_if_any_arg_is_an_array_and_needs_lbound_or_ubound(node.entry.params, node.args)
        yield node

    def visit_CALL(self, node):
        node.args = (yield self.generic_visit(node.args))  # Avoid infinite recursion not visiting node.entry
        self._check_if_any_arg_is_an_array_and_needs_lbound_or_ubound(node.entry.params, node.args)
        yield node

    def visit_FUNCDECL(self, node):
        if self.O_LEVEL > 1 and not node.entry.accessed:
            warning(node.entry.lineno, "Function '%s' is never called and has been ignored" % node.entry.name)
            yield self.NOP
        else:
            node.children[1] = (yield ToVisit(node.entry))
            yield node

    def visit_FUNCTION(self, node):
        if getattr(node, 'visited', False):
            yield node
        else:
            node.visited = True
            yield (yield self.generic_visit(node))

    def visit_LET(self, node):
        if self.O_LEVEL > 1 and not node.children[0].accessed:
            warning_not_used(node.children[0].lineno, node.children[0].name)
            yield symbols.BLOCK(*list(self.filter_inorder(node.children[1], lambda x: isinstance(x, symbols.CALL))))
        else:
            yield (yield self.generic_visit(node))

    def visit_LETSUBSTR(self, node):
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

    def visit_BLOCK(self, node):
        if self.O_LEVEL >= 1 and chk.is_null(node):
            yield self.NOP
            return
        yield (yield self.generic_visit(node))

    def visit_IF(self, node):
        expr_ = (yield ToVisit(node.children[0]))
        then_ = (yield ToVisit(node.children[1]))
        else_ = (yield ToVisit(node.children[2])) if len(node.children) == 3 else self.NOP

        if self.O_LEVEL >= 1:
            if chk.is_null(then_, else_):
                api.errmsg.warning_empty_if(node.lineno)
                yield self.NOP
                return

            block_accessed = chk.is_block_accessed(then_) or chk.is_block_accessed(else_)
            if not block_accessed and chk.is_number(expr_):  # constant condition
                if expr_.value:  # always true (then_)
                    yield then_
                else:            # always false (else_)
                    yield else_
                return

            if chk.is_null(else_) and len(node.children) == 3:
                node.children.pop()  # remove empty else
                yield node
                return

        for i in range(len(node.children)):
            node.children[i] = (expr_, then_, else_)[i]
        yield node

    def visit_WHILE(self, node):
        expr_ = (yield node.children[0])
        body_ = (yield node.children[1])

        if self.O_LEVEL >= 1:
            if chk.is_number(expr_) and not expr_.value and not chk.is_block_accessed(body_):
                yield self.NOP
                return

        for i, child in enumerate((expr_, body_)):
            node.children[i] = child
        yield node

    def visit_FOR(self, node):
        from_ = (yield node.children[1])
        to_ = (yield node.children[2])
        step_ = (yield node.children[3])
        body_ = (yield node.children[4])

        if self.O_LEVEL > 0 and chk.is_number(from_, to_, step_) and not chk.is_block_accessed(body_):
            if from_ > to_ and step_ > 0:
                yield self.NOP
                return
            if from_ < to_ and step_ < 0:
                yield self.NOP
                return

        for i, child in enumerate((from_, to_, step_, body_), start=1):
            node.children[i] = child
        yield node

    # TODO: ignore unused labels
    def _visit_LABEL(self, node):
        if self.O_LEVEL and not node.accessed:
            yield self.NOP
        else:
            yield node

    @staticmethod
    def generic_visit(node):
        for i in range(len(node.children)):
            node.children[i] = (yield ToVisit(node.children[i]))
        yield node

    def _check_if_any_arg_is_an_array_and_needs_lbound_or_ubound(self, params: symbols.PARAMLIST,
                                                                 args: symbols.ARGLIST):
        """ Given a list of params and a list of args, traverse them to check if any arg is a byRef array parameter,
        and if so, whether it's use_lbound or use_ubound flag is updated to True and if it's a local var. If so, it's
        offset size has changed and must be reevaluated!
        """
        for arg, param in zip(args, params):
            if not param.byref or param.class_ != CLASS.array:
                continue

            if arg.value.lbound_used and arg.value.ubound_used:
                continue

            self._update_bound_status(arg.value)

    def _update_bound_status(self, arg: symbols.VARARRAY):
        old_lbound_used = arg.lbound_used
        old_ubound_used = arg.ubound_used

        for p in arg.requires:
            arg.lbound_used = arg.lbound_used or p.lbound_used
            arg.ubound_used = arg.ubound_used or p.ubound_used

        if old_lbound_used != arg.lbound_used or old_ubound_used != arg.ubound_used:
            if arg.scope == SCOPE.global_:
                return

            if arg.scope == SCOPE.local and not arg.byref:
                arg.scopeRef.owner.locals_size = api.symboltable.SymbolTable.compute_offsets(arg.scopeRef)
