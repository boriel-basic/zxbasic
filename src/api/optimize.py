#!/usr/bin/env python
# -*- coding: utf-8 -*-

from typing import NamedTuple
from typing import Optional
from typing import Set

import src.api.global_ as gl
import src.api.utils
import src.api.symboltable
import src.api.check as chk

from src import symbols
from src.ast import NodeVisitor
from src.api import errmsg

from src.api.constants import TYPE, SCOPE, CLASS, CONVENTION
from src.api.debug import __DEBUG__
from src.api.errmsg import warning_not_used

from src.api.config import OPTIONS


class ToVisit(NamedTuple):
    """Used just to signal an object to be
    traversed.
    """

    obj: symbols.SYMBOL


class GenericVisitor(NodeVisitor):
    """A slightly different visitor, that just traverses an AST, but does not return
    a translation of it. Used to examine the AST or do transformations
    """

    node_type = ToVisit

    @property
    def O_LEVEL(self):
        return OPTIONS.optimization_level

    NOP = symbols.NOP()  # Return this for "erased" nodes

    @staticmethod
    def TYPE(type_):
        """Converts a backend type (from api.constants)
        to a SymbolTYPE object (taken from the SYMBOL_TABLE).
        If type_ is already a SymbolTYPE object, nothing
        is done.
        """
        if isinstance(type_, symbols.TYPE):
            return type_

        assert TYPE.is_valid(type_)
        return gl.SYMBOL_TABLE.basic_types[type_]

    def visit(self, node):
        return super().visit(ToVisit(node))

    def _visit(self, node: ToVisit):
        if node.obj is None:
            return None

        __DEBUG__(f"Optimizer: Visiting node {str(node.obj)}", 1)
        meth = getattr(self, f"visit_{node.obj.token}", self.generic_visit)
        return meth(node.obj)

    def generic_visit(self, node: symbols.SYMBOL):
        for i, child in enumerate(node.children):
            node.children[i] = yield self.visit(child)

        yield node


class UniqueVisitor(GenericVisitor):
    def __init__(self):
        super().__init__()
        self.visited = set()

    def _visit(self, node: ToVisit):
        if node.obj in self.visited:
            return node.obj

        self.visited.add(node.obj)
        return super()._visit(node)


class UnreachableCodeVisitor(UniqueVisitor):
    """Visitor to optimize unreachable code (and prune it)."""

    def visit_FUNCTION(self, node: symbols.FUNCTION):
        if (
            node.class_ == CLASS.function
            and node.body.token == "BLOCK"
            and (not node.body or node.body[-1].token != "RETURN")
        ):
            # String functions must *ALWAYS* return a value.
            # Put a sentinel ("dummy") return "" sentence that will be removed if other is detected
            lineno = node.lineno if not node.body else node.body[-1].lineno
            errmsg.warning_function_should_return_a_value(lineno, node.name, node.filename)
            type_ = node.type_
            if type_ is not None and type_ == self.TYPE(TYPE.string):
                node.body.append(symbols.ASM("\nld hl, 0\n", lineno, node.filename, is_sentinel=True))

        yield (yield self.generic_visit(node))

    def visit_BLOCK(self, node):
        warning_emitted = False
        i = 0
        while i < len(node):
            sentence = node[i]
            if chk.is_ender(sentence):
                j = i + 1
                while j < len(node):
                    if chk.is_LABEL(node[j]):
                        break

                    if node[j].token == "FUNCDECL":
                        j += 1
                        continue

                    if (
                        node[j].token == "SENTENCE" and node[j].is_sentinel
                    ):  # "Sentinel" instructions can be freely removed
                        node.pop(j)
                        continue

                    if node[j].token == "ASM":
                        break  # User's ASM must always be left there

                    if not warning_emitted and self.O_LEVEL > 0:
                        warning_emitted = True
                        errmsg.warning_unreachable_code(lineno=node[j].lineno, fname=node[j].filename)

                        if self.O_LEVEL < 2:
                            break

                    node.pop(j)
            i += 1

        if self.O_LEVEL >= 1 and chk.is_null(node):
            yield self.NOP
            return

        yield (yield self.generic_visit(node))


class FunctionGraphVisitor(UniqueVisitor):
    """Mark FUNCALLS"""

    def _get_calls_from_children(self, node):
        return [
            symbol
            for symbol in self.filter_inorder(node, lambda x: isinstance(x, (symbols.FUNCCALL, symbols.CALL)))
            if not isinstance(symbol, symbols.ARRAYACCESS)
        ]

    def _set_children_as_accessed(self, node: symbols.SYMBOL):
        parent = node.get_parent(symbols.FUNCDECL)
        if parent is None:  # Global scope?
            for symbol in self._get_calls_from_children(node):
                symbol.entry.accessed = True

    def visit_FUNCCALL(self, node: symbols.FUNCCALL):
        self._set_children_as_accessed(node)
        yield node

    def visit_CALL(self, node: symbols.CALL):
        self._set_children_as_accessed(node)
        yield node

    def visit_FUNCDECL(self, node: symbols.FUNCDECL):
        if node.entry.accessed:
            for symbol in self._get_calls_from_children(node):
                symbol.entry.accessed = True

        yield node

    def visit_GOTO(self, node: symbols.SENTENCE):
        parent = node.get_parent(symbols.FUNCDECL)
        if parent is None:  # Global scope?
            node.args[0].accessed = True
        yield node

    def visit_GOSUB(self, node: symbols.SENTENCE):
        return self.visit_GOTO(node)


class OptimizerVisitor(UniqueVisitor):
    """Implements some optimizations"""

    def visit(self, node):
        if self.O_LEVEL < 1:  # Optimize only if O1 or above
            return node

        return super().visit(node)

    def visit_ADDRESS(self, node):
        if node.operand.token != "ARRAYACCESS":
            if not chk.is_dynamic(node.operand):
                node = symbols.CONST(node, node.lineno)
        elif node.operand.offset is not None:  # A constant access
            if node.operand.scope == SCOPE.global_:  # Calculate offset if global variable
                node = symbols.BINARY.make_node(
                    "PLUS",
                    symbols.UNARY("ADDRESS", node.operand.entry, node.lineno, type_=self.TYPE(gl.PTR_TYPE)),
                    symbols.NUMBER(node.operand.offset, lineno=node.operand.lineno, type_=self.TYPE(gl.PTR_TYPE)),
                    lineno=node.lineno,
                    func=lambda x, y: x + y,
                )
        yield node

    def visit_BINARY(self, node: symbols.BINARY):
        node = yield self.generic_visit(node)  # This might convert consts to numbers if possible
        # Retry folding
        yield symbols.BINARY.make_node(node.operator, node.left, node.right, node.lineno, node.func, node.type_)

    def visit_BUILTIN(self, node):
        methodname = "visit_" + node.fname
        if hasattr(self, methodname):
            yield (yield getattr(self, methodname)(node))
        else:
            yield (yield self.generic_visit(node))

    def visit_CHR(self, node):
        node = yield self.generic_visit(node)

        if all(chk.is_static(arg.value) for arg in node.operand):
            yield symbols.STRING(
                "".join(chr(src.api.utils.get_final_value(x.value) & 0xFF) for x in node.operand), node.lineno
            )
        else:
            yield node

    def visit_CONST(self, node):
        if chk.is_number(node.expr) or chk.is_const(node.expr):
            yield node.expr
        else:
            yield node

    def visit_FUNCCALL(self, node):
        node.args = yield self.generic_visit(node.args)  # Avoid infinite recursion not visiting node.entry
        self._check_if_any_arg_is_an_array_and_needs_lbound_or_ubound(node.entry.params, node.args)
        yield node

    def visit_CALL(self, node):
        node.args = yield self.generic_visit(node.args)  # Avoid infinite recursion not visiting node.entry
        self._check_if_any_arg_is_an_array_and_needs_lbound_or_ubound(node.entry.params, node.args)
        yield node

    def visit_FUNCDECL(self, node):
        if self.O_LEVEL > 1 and not node.entry.accessed:
            errmsg.warning_func_is_never_called(node.entry.lineno, node.entry.name, fname=node.entry.filename)
            yield self.NOP
            return

        if self.O_LEVEL > 1 and node.params_size == node.locals_size == 0:
            node.entry.convention = CONVENTION.fastcall

        node.children[1] = yield ToVisit(node.entry)
        yield node

    def visit_LET(self, node):
        lvalue = node.children[0]
        if self.O_LEVEL > 1 and not lvalue.accessed:
            warning_not_used(lvalue.lineno, lvalue.name, fname=lvalue.filename)
            block = symbols.BLOCK(
                *[
                    symbols.CALL(x.entry, x.args, x.lineno, lvalue.filename)
                    for x in self.filter_inorder(
                        node.children[1],
                        lambda x: isinstance(x, symbols.FUNCCALL),
                        lambda x: not isinstance(x, symbols.FUNCTION),
                    )
                ]
            )
            yield block
        else:
            yield (yield self.generic_visit(node))

    def visit_LETARRAY(self, node):
        lvalue = node.args[0].entry
        if self.O_LEVEL > 1 and not lvalue.accessed:
            warning_not_used(lvalue.lineno, lvalue.name, fname=lvalue.filename)
            block = symbols.BLOCK(
                *[
                    symbols.CALL(x.entry, x.args, x.lineno, lvalue.filename)
                    for x in self.filter_inorder(
                        node.children[1],
                        lambda x: isinstance(x, symbols.FUNCCALL),
                        lambda x: not isinstance(x, symbols.FUNCTION),
                    )
                ]
            )
            yield block
        else:
            yield (yield self.generic_visit(node))

    def visit_LETSUBSTR(self, node):
        if self.O_LEVEL > 1 and not node.children[0].accessed:
            errmsg.warning_not_used(node.children[0].lineno, node.children[0].name)
            yield self.NOP
        else:
            yield (yield self.generic_visit(node))

    def visit_RETURN(self, node):
        """Visits only children[1], since children[0] points to
        the current function being returned from (if any), and
        might cause infinite recursion.
        """
        if len(node.children) == 2:
            node.children[1] = yield ToVisit(node.children[1])
        yield node

    def visit_UNARY(self, node):
        if node.operator == "ADDRESS":
            yield (yield self.visit_ADDRESS(node))
        else:
            yield (yield self.generic_visit(node))

    def visit_IF(self, node):
        expr_ = yield ToVisit(node.children[0])
        then_ = yield ToVisit(node.children[1])
        else_ = (yield ToVisit(node.children[2])) if len(node.children) == 3 else self.NOP

        if self.O_LEVEL >= 1:
            if chk.is_null(then_, else_):
                src.api.errmsg.warning_empty_if(node.lineno)
                yield self.NOP
                return

            block_accessed = chk.is_block_accessed(then_) or chk.is_block_accessed(else_)
            if not block_accessed and chk.is_number(expr_):  # constant condition
                if expr_.value:  # always true (then_)
                    yield then_
                else:  # always false (else_)
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
        expr_ = yield node.children[0]
        body_ = yield node.children[1]

        if self.O_LEVEL >= 1:
            if chk.is_number(expr_) and not expr_.value and not chk.is_block_accessed(body_):
                yield self.NOP
                return

        for i, child in enumerate((expr_, body_)):
            node.children[i] = child
        yield node

    def visit_FOR(self, node):
        from_ = yield node.children[1]
        to_ = yield node.children[2]
        step_ = yield node.children[3]
        body_ = yield node.children[4]

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

    def generic_visit(self, node: symbols.SYMBOL):
        for i in range(len(node.children)):
            node.children[i] = yield ToVisit(node.children[i])

        yield node

    def _check_if_any_arg_is_an_array_and_needs_lbound_or_ubound(
        self, params: symbols.PARAMLIST, args: symbols.ARGLIST
    ):
        """Given a list of params and a list of args, traverse them to check if any arg is a byRef array parameter,
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
                arg.scopeRef.owner.locals_size = src.api.symboltable.SymbolTable.compute_offsets(arg.scopeRef)


class VarDependency(NamedTuple):
    parent: symbols.VAR
    dependency: symbols.VAR


class VariableVisitor(GenericVisitor):
    _original_variable: Optional[symbols.VAR] = None
    _parent_variable = None
    _visited: Set[symbols.SYMBOL] = set()

    def generic_visit(self, node: symbols.SYMBOL):
        if node not in VariableVisitor._visited:
            VariableVisitor._visited.add(node)
            for i in range(len(node.children)):
                node.children[i] = yield ToVisit(node.children[i])

            yield node

    def has_circular_dependency(self, var_dependency: VarDependency) -> bool:
        if var_dependency.dependency == VariableVisitor._original_variable:
            src.api.errmsg.error(
                VariableVisitor._original_variable.lineno,
                "Circular dependency between '{}' and '{}'".format(
                    VariableVisitor._original_variable.name, var_dependency.parent
                ),
            )
            return True

        return False

    def get_var_dependencies(self, var_entry: symbols.VAR):
        visited: Set[symbols.VAR] = set()
        result = set()

        def visit_var(entry):
            if entry in visited:
                return

            visited.add(entry)
            if not isinstance(entry, symbols.VAR):
                for child in entry.children:
                    visit_var(child)
                    if isinstance(child, symbols.VAR):
                        result.add(VarDependency(parent=VariableVisitor._parent_variable, dependency=child))
                return

            VariableVisitor._parent_variable = entry
            if entry.alias is not None:
                result.add(VarDependency(parent=entry, dependency=entry.alias))
                visit_var(entry.alias)
            elif entry.addr is not None:
                visit_var(entry.addr)

        visit_var(var_entry)
        return result

    def visit_VARDECL(self, node: symbols.VARDECL):
        """Checks for cyclic dependencies in aliasing variables"""
        VariableVisitor._visited = set()
        VariableVisitor._original_variable = node.entry
        for dependency in self.get_var_dependencies(node.entry):
            if self.has_circular_dependency(dependency):
                break

        VariableVisitor._visited = set()
        VariableVisitor._original_variable = VariableVisitor._parent_variable = None
        yield node
