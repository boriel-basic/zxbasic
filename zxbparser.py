#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import sys
# PI Constant
# PI = 3.1415927 is ZX Spectrum PI representation
# But a better one is 3.141592654, so take it from math
import math
from math import pi as PI
import collections

# Compiler API
import api
from api.debug import __DEBUG__  # analysis:ignore
from api.opcodestemps import OpcodesTemps
from api.errmsg import syntax_error
from api.errmsg import warning
from api.check import *

from api.constants import CLASS
from api.constants import SCOPE
from api.constants import KIND
from api.constants import CONVENTION
import api.errmsg
import api.symboltable

# Symbol Classes
import symbols
from symbols.type_ import Type as TYPE
from symbols.symbol_ import Symbol

# Global containers
from api import global_ as gl
from api.config import OPTIONS

# Lexers and parsers, etc
import ply.yacc as yacc
import zxblex
import zxbpp
from backend import REQUIRES
from zxblex import tokens  # analysis:ignore -- Needed for PLY. Do not remove.

# ----------------------------------------------------------------------
# Function level entry ID in which scope we are into. If the list
# is empty, we are at global scope
# ----------------------------------------------------------------------
FUNCTION_LEVEL = gl.FUNCTION_LEVEL

# ----------------------------------------------------------------------
# Function calls pending to check
# Each scope pushes (prepends) an empty list
# ----------------------------------------------------------------------
FUNCTION_CALLS = gl.FUNCTION_CALLS

# ----------------------------------------------------------------------
# Initialization routines to be called automatically at program start
# ----------------------------------------------------------------------
INITS = gl.INITS

# ----------------------------------------------------------------------
# Global Symbol Table
# ----------------------------------------------------------------------
SYMBOL_TABLE = gl.SYMBOL_TABLE = api.symboltable.SymbolTable()

# ----------------------------------------------------------------------
# Defined user labels. They all are prepended _label_. Line numbers 10,
# 20, 30... are in the form: __label_10, __label_20, __label_30...
# ----------------------------------------------------------------------
LABELS = {}

# ----------------------------------------------------------------------
# True if we're in the middle of a LET sentence. False otherwise.
# ----------------------------------------------------------------------
LET_ASSIGNMENT = False

# ----------------------------------------------------------------------
# True if PRINT sentence has been used.
# ----------------------------------------------------------------------
PRINT_IS_USED = False


# ----------------------------------------------------------------------
# "Macro" functions. Just return more complex expresions
# ----------------------------------------------------------------------
def _TYPE(type_):
    """ returns an internal type converted to a SYMBOL_TABLE
    type.
    """
    return SYMBOL_TABLE.basic_types[type_]


# ----------------------------------------------------------------------
# Wrapper functions to make AST nodes
# ----------------------------------------------------------------------
def make_nop():
    """ NOP does nothing.
    """
    return symbols.NOP()


def make_number(value, lineno, type_=None):
    """ Wrapper: creates a constant number node.
    """
    return symbols.NUMBER(value, type_=type_, lineno=lineno)


def make_typecast(type_, node, lineno):
    """ Wrapper: returns a Typecast node
    """
    assert isinstance(type_, symbols.TYPE)
    return symbols.TYPECAST.make_node(type_, node, lineno)


def make_binary(lineno, operator, left, right, func=None, type_=None):
    """ Wrapper: returns a Binary node
    """
    return symbols.BINARY.make_node(operator, left, right, lineno, func, type_)


def make_unary(lineno, operator, operand, func=None, type_=None):
    """ Wrapper: returns a Unary node
    """
    return symbols.UNARY.make_node(lineno, operator, operand, func, type_)


def make_builtin(lineno, fname, operands, func=None, type_=None):
    """ Wrapper: returns a Builtin function node.
    Can be a Symbol, tuple or list of Symbols
    If operand is an iterable, they will be expanded.
    """
    if operands is None:
        operands = []
    assert isinstance(operands, Symbol) or isinstance(operands, tuple) or isinstance(operands, list)
    # TODO: In the future, builtin functions will be implemented in an externnal library, like POINT or ATTR
    # HINT: They are not yet, because Sinclair BASIC grammar allows not to use parenthesis e.g. SIN x = SIN(x)
    # HINT: which requires syntactical changes in the parser
    __DEBUG__('Creating BUILTIN "{}"'.format(fname), 1)
    if not isinstance(operands, collections.Iterable):
        operands = [operands]
    return symbols.BUILTIN.make_node(lineno, fname, func, type_, *operands)


def make_constexpr(lineno, expr):
    return symbols.CONST(expr, lineno=lineno)


def make_strslice(lineno, s, lower, upper):
    """ Wrapper: returns Strlice node
    """
    return symbols.STRSLICE.make_node(lineno, s, lower, upper)


def make_sentence(sentence, *args):
    """ Wrapper: returns a Sentence node
    """
    return symbols.SENTENCE(sentence, *args)


def make_asm_sentence(asm, lineno):
    """ Creates a node for an ASM inline sentence
    """
    return symbols.ASM(asm, lineno)


def make_block(*args):
    """ Wrapper: Creates a chain of code blocks.
    """
    return symbols.BLOCK.make_node(*args)


def make_var_declaration(entry):
    """ This will return a node with a var declaration.
    The children node contains the symbol table entry.
    """
    return symbols.VARDECL(entry)


def make_array_declaration(entry):
    """ This will return a node with the symbol as an array.
    """
    return symbols.ARRAYDECL(entry)


def make_func_declaration(func_name, lineno):
    """ This will return a node with the symbol as a function.
    """
    return symbols.FUNCDECL.make_node(func_name, lineno)


def make_arg_list(node, *args):
    """ Wrapper: returns a node with an argument_list.
    """
    return symbols.ARGLIST.make_node(node, *args)


def make_argument(expr, lineno, byref=None):
    """ Wrapper: Creates a node containing an ARGUMENT
    """
    if expr is None:
        return  # There were a syntax / semantic error

    if byref is None:
        byref = OPTIONS.byref.value
    return symbols.ARGUMENT(expr, lineno=lineno, byref=byref)


def make_param_list(node, *args):
    """ Wrapper: Returns a param declaration list (function header)
    """
    return symbols.PARAMLIST.make_node(node, *args)


def make_sub_call(id_, lineno, params):
    """ This will return an AST node for a sub/procedure call.
    """
    return symbols.CALL.make_node(id_, params, lineno)


def make_func_call(id_, lineno, params):
    """ This will return an AST node for a function call.
    """
    return symbols.FUNCCALL.make_node(id_, params, lineno)


def make_array_access(id_, lineno, arglist):
    """ Creates an array access. A(x1, x2, ..., xn).
    This is an RVALUE (Read the element)
    """
    return symbols.ARRAYACCESS.make_node(id_, arglist, lineno)


def make_call(id_, lineno, args):
    """ This will return an AST node for a function call/array access.

    A "call" is just an ID followed by a list of arguments.
    E.g. a(4)
    - a(4) can be a function call if 'a' is a function
    - a(4) can be a string slice if a is a string variable: a$(4)
    - a(4) can be an access to an array if a is an array

    This function will inspect the id_. If it is undeclared then
    id_ will be taken as a forwarded function.
    """
    assert isinstance(args, symbols.ARGLIST)

    entry = SYMBOL_TABLE.access_call(id_, lineno)
    if entry is None:
        return None

    if entry.class_ is CLASS.unknown and entry.type_ == TYPE.string and len(args) == 1:
        entry.class_ = CLASS.var  # A scalar variable. e.g a$(expr)

    if entry.class_ == CLASS.array:  # An already declared array
        arr = symbols.ARRAYLOAD.make_node(id_, args, lineno)
        if arr is None:
            return None

        if arr.offset is not None:
            offset = make_typecast(TYPE.uinteger,
                                   make_number(arr.offset, lineno=lineno),
                                   lineno)
            arr.appendChild(offset)
        return arr

    if entry.class_ == CLASS.var:  # An already declared/used string var
        if len(args) > 1:
            api.errmsg.syntax_error_not_array_nor_func(lineno, id_)
            return None

        entry = SYMBOL_TABLE.access_var(id_, lineno)
        if entry is None:
            return None

        if len(args) == 1:
            return symbols.STRSLICE.make_node(lineno, entry, args[0].value,
                                              args[0].value)
        entry.accessed = True
        return entry

    return make_func_call(id_, lineno, args)


def make_param_decl(id_, lineno, typedef):
    """ Wrapper that creates a param declaration
    """
    return SYMBOL_TABLE.declare_param(id_, lineno, typedef)


def make_type(typename, lineno, implicit=False):
    """ Converts a typename identifier (e.g. 'float') to
    its internal symbol table entry representation.

    Creates a type usage symbol stored in a AST
    E.g. DIM a As Integer
    will access Integer type
    """
    assert isinstance(typename, str)
    if not SYMBOL_TABLE.check_is_declared(typename, lineno, 'type'):
        return None

    type_ = symbols.TYPEREF(SYMBOL_TABLE.get_entry(typename), lineno, implicit)
    return type_


def make_bound(lower, upper, lineno):
    """ Wrapper: Creates an array bound
    """
    return symbols.BOUND.make_node(lower, upper, lineno)


def make_bound_list(node, *args):
    """ Wrapper: Creates an array BOUND LIST.
    """
    return symbols.BOUNDLIST.make_node(node, *args)


def make_label(id_, lineno):
    """ Creates a label entry. Returns None on error.
    """
    return SYMBOL_TABLE.declare_label(id_, lineno)


# ----------------------------------------------------------------------
# Operators precedence
# ----------------------------------------------------------------------
precedence = (
    ('left', 'OR'),
    ('left', 'AND'),
    ('left', 'XOR'),
    ('right', 'NOT'),
    ('left', 'LT', 'GT', 'EQ', 'LE', 'GE', 'NE'),
    ('left', 'BOR'),
    ('left', 'BAND', 'BXOR', 'SHR', 'SHL'),
    ('left', 'BNOT', 'PLUS', 'MINUS'),
    ('left', 'MOD'),
    ('left', 'MUL', 'DIV'),
    ('right', 'UMINUS'),
    ('right', 'POW'),
)


# ----------------------------------------------------------------------
# Grammar rules
# ----------------------------------------------------------------------

def p_start(p):
    """ start : program
    """
    global ast, data_ast

    user_data = make_label('.ZXBASIC_USER_DATA', 0)
    make_label('.ZXBASIC_USER_DATA_LEN', 0)

    if PRINT_IS_USED:
        zxbpp.ID_TABLE.define('___PRINT_IS_USED___', 1)
        # zxbasmpp.ID_TABLE.define('___PRINT_IS_USED___', 1)

    if zxblex.IN_STATE:
        p.type = 'NEWLINE'
        p_error(p)
        sys.exit(1)

    ast = p[0] = p[1]
    __end = make_sentence('END', make_number(0, lineno=p.lexer.lineno))

    if not is_null(ast):
        ast.appendChild(__end)
    else:
        ast = __end

    SYMBOL_TABLE.check_labels()
    SYMBOL_TABLE.check_classes()

    if gl.has_errors:
        return

    __DEBUG__('Checking pending labels', 1)
    if not api.check.check_pending_labels(ast):
        return

    __DEBUG__('Checking pending calls', 1)
    if not api.check.check_pending_calls():
        return

    data_ast = make_sentence('BLOCK', user_data)

    # Appends variable declarations at the end.
    for var in SYMBOL_TABLE.vars_:
        data_ast.appendChild(make_var_declaration(var))

    # Appends arrays declarations at the end.
    for var in SYMBOL_TABLE.arrays:
        data_ast.appendChild(make_array_declaration(var))


def p_program_program_line(p):
    """ program : program_line
    """
    if OPTIONS.enableBreak.value:
        lineno = p.lexer.lineno
        tmp = make_sentence('CHKBREAK',
                            make_number(lineno, lineno, TYPE.uinteger))
        p[0] = make_block(p[1], tmp)
    else:
        p[0] = make_block(p[1])


def p_program(p):
    """ program : program program_line
    """
    if OPTIONS.enableBreak.value:
        lineno = p.lexer.lineno
        tmp = make_sentence('CHKBREAK',
                            make_number(lineno, lineno, TYPE.uinteger))
        p[0] = make_block(p[1], p[2], tmp)
    else:
        p[0] = make_block(p[1], p[2])


def p_program_line_(p):
    """ program_line : statement
                | var_decl
                | preproc_line
                | label_line
    """
    p[0] = p[1]


def p_program_line_label(p):
    """ label_line : LABEL statement
                   | LABEL var_decl
    """
    p[0] = make_block(make_label(p[1], p.lineno(1)), p[2])


def p_program_line_label2(p):
    """ program_line : ID CO NEWLINE
    """
    p[0] = make_label(p[1], p.lineno(1))


def p_var_decl(p):
    """ var_decl : DIM idlist typedef NEWLINE
                 | DIM idlist typedef CO
    """
    for vardata in p[2]:
        SYMBOL_TABLE.declare_variable(vardata[0], vardata[1], p[3])

    p[0] = None  # Variable declarations are made at the end of parsing


def p_var_decl_at(p):
    """ var_decl : DIM idlist typedef AT expr CO
                 | DIM idlist typedef AT expr NEWLINE
    """
    p[0] = None

    if len(p[2]) != 1:
        syntax_error(p.lineno(1),
                     'Only one variable at a time can be declared this way')
        return

    idlist = p[2][0]

    entry = SYMBOL_TABLE.declare_variable(idlist[0], idlist[1], p[3])
    if entry is None:
        return

    if p[5].token == 'CONST':
        tmp = p[5].expr
        if tmp.token == 'UNARY' and tmp.operator == 'ADDRESS':  # Must be an ID
            if tmp.operand.token == 'VAR':
                entry.make_alias(tmp.operand)
            elif tmp.operand.token == 'ARRAYACCESS':
                if tmp.operand.offset is None:
                    syntax_error(p.lineno(4), 'Address is not constant. Only constant subscripts are allowed')
                    return

                entry.make_alias(tmp.operand)
                entry.offset = tmp.operand.offset
            else:
                syntax_error(p.lineno(4), 'Only address of identifiers are allowed')
                return

    elif not is_number(p[5]):
        syntax_error(p.lineno(4), 'Address must be a numeric constant expression')
        return
    else:
        entry.addr = str(make_typecast(_TYPE(gl.STR_INDEX_TYPE), p[5], p.lineno(4)).value)
        if entry.scope == SCOPE.local:
            SYMBOL_TABLE.make_static(entry.name)


def p_var_decl_ini(p):
    """ var_decl : DIM idlist typedef EQ expr NEWLINE
                 | DIM idlist typedef EQ expr CO
                 | CONST idlist typedef EQ expr NEWLINE
                 | CONST idlist typedef EQ expr CO
    """
    p[0] = None
    if len(p[2]) != 1:
        syntax_error(p.lineno(1),
                     "Initialized variables must be declared one by one.")
        return

    if not is_static(p[5]):
        api.errmsg.syntax_error_not_constant(p.lineno(1))
        return

    defval = make_typecast(p[3], p[5], p.lineno(4))

    if p[1] == 'DIM':
        SYMBOL_TABLE.declare_variable(p[2][0][0], p[2][0][1], p[3],
                                      default_value=defval)
    else:
        SYMBOL_TABLE.declare_const(p[2][0][0], p[2][0][1], p[3],
                                   default_value=defval)


def p_idlist_id(p):
    """ idlist : ID
    """
    p[0] = [(p[1], p.lineno(1))]


def p_idlist_idlist_id(p):
    """ idlist : idlist COMMA ID
    """
    p[0] = p[1] + [(p[3], p.lineno(3))]


def p_arr_decl(p):
    """ var_decl : DIM ID LP bound_list RP typedef NEWLINE
                 | DIM ID LP bound_list RP typedef CO
    """
    SYMBOL_TABLE.declare_array(p[2], p.lineno(2), p[6], p[4])
    p[0] = None


def p_arr_decl_initialized(p):
    """ var_decl : DIM ID LP bound_list RP typedef RIGHTARROW const_vector NEWLINE
                 | DIM ID LP bound_list RP typedef RIGHTARROW const_vector CO
                 | DIM ID LP bound_list RP typedef EQ const_vector NEWLINE
                 | DIM ID LP bound_list RP typedef EQ const_vector CO
    """

    def check_bound(boundlist, remaining):
        """ Checks if constant vector bounds matches the array one
        """
        if not boundlist:  # Returns on empty list
            if not isinstance(remaining, list):
                return True  # It's OK :-)

            syntax_error(p.lineno(9), 'Unexpected extra vector dimensions. It should be %i' % len(remaining))

        if not isinstance(remaining, list):
            syntax_error(p.lineno(9), 'Mismatched vector size. Missing %i extra dimension(s)' % len(boundlist))
            return False

        if len(remaining) != boundlist[0].count:
            syntax_error(p.lineno(9), 'Mismatched vector size. Expected %i elements, got %i.' % (boundlist[0].count,
                                                                                                 len(remaining)))
            return False  # It's wrong. :-(

        for row in remaining:
            if not check_bound(boundlist[1:], row):
                return False

        return True

    if p[8] is None:
        p[0] = None
        return

    if check_bound(p[4].children, p[8]):
        SYMBOL_TABLE.declare_array(p[2], p.lineno(2), p[6], p[4], default_value=p[8])

    p[0] = None


def p_bound_list(p):
    """ bound_list : bound
    """
    p[0] = make_bound_list(p[1])


def p_bound_list_bound(p):
    """ bound_list : bound_list COMMA bound
    """
    p[0] = make_bound_list(p[1], p[3])


def p_bound(p):
    """ bound : expr
    """
    p[0] = make_bound(make_number(OPTIONS.array_base.value,
                                  lineno=p.lineno(1)), p[1], p.lexer.lineno)


def p_bound_to_bound(p):
    """ bound : expr TO expr
    """
    p[0] = make_bound(p[1], p[3], p.lineno(2))


def p_const_vector(p):
    """ const_vector : LBRACE const_vector_list RBRACE
                     | LBRACE const_number_list RBRACE
    """
    p[0] = p[2]


def p_const_vector_elem_list(p):
    """ const_number_list : expr
    """
    if not is_number(p[1]):
        api.errmsg.syntax_error_not_constant(p.lexer.lineno)
        p[0] = None
        return

    p[0] = [p[1]]


def p_const_vector_elem_list_list(p):
    """ const_number_list : const_number_list COMMA expr
    """
    if not is_number(p[3]):
        api.errmsg.syntax_error_not_constant(p.lineno(2))
        p[0] = None
        return

    if p[1] is None:
        return

    p[0] = p[1] + [p[3]]


def p_const_vector_list(p):
    """ const_vector_list : const_vector
    """
    p[0] = [p[1]]


def p_const_vector_vector_list(p):
    """ const_vector_list : const_vector_list COMMA const_vector
    """
    if len(p[3]) != len(p[1][0]):
        syntax_error(p.lineno(2),
                     'All rows must have the same number of elements')
        p[0] = None
        return

    p[0] = p[1] + [p[3]]


def p_empty_statement(p):
    """ statement : NEWLINE
                  | CO
    """
    p[0] = None


def p_staement_func_decl(p):
    """ statement : function_declaration
    """
    p[0] = p[1]


def p_statement_border(p):
    """ statement : BORDER expr NEWLINE
                  | BORDER expr CO
    """
    p[0] = make_sentence('BORDER',
                         make_typecast(TYPE.ubyte, p[2], p.lineno(3)))


def p_statement_plot(p):
    """ statement : PLOT expr COMMA expr NEWLINE
                  | PLOT expr COMMA expr CO
    """
    p[0] = make_sentence('PLOT',
                         make_typecast(TYPE.ubyte, p[2], p.lineno(3)),
                         make_typecast(TYPE.ubyte, p[4], p.lineno(5)))


def p_statement_plot_attr(p):
    """ statement : PLOT attr_list expr COMMA expr NEWLINE
                  | PLOT attr_list expr COMMA expr CO
    """
    p[0] = make_sentence('PLOT',
                         make_typecast(TYPE.ubyte, p[3], p.lineno(4)),
                         make_typecast(TYPE.ubyte, p[5], p.lineno(6)), p[2])


def p_statement_draw3(p):
    """ statement : DRAW expr COMMA expr COMMA expr NEWLINE
                  | DRAW expr COMMA expr COMMA expr CO
    """
    p[0] = make_sentence('DRAW3',
                         make_typecast(TYPE.integer, p[2], p.lineno(3)),
                         make_typecast(TYPE.integer, p[4], p.lineno(5)),
                         make_typecast(TYPE.float_, p[6], p.lineno(7)))


def p_statement_draw3_attr(p):
    """ statement : DRAW attr_list expr COMMA expr COMMA expr NEWLINE
                  | DRAW attr_list expr COMMA expr COMMA expr CO
    """
    p[0] = make_sentence('DRAW3',
                         make_typecast(TYPE.integer, p[3], p.lineno(4)),
                         make_typecast(TYPE.integer, p[5], p.lineno(6)),
                         make_typecast(TYPE.float_, p[7], p.lineno(8)), p[2])


def p_statement_draw(p):
    """ statement : DRAW expr COMMA expr NEWLINE
                  | DRAW expr COMMA expr CO
    """
    p[0] = make_sentence('DRAW',
                         make_typecast(TYPE.integer, p[2], p.lineno(3)),
                         make_typecast(TYPE.integer, p[4], p.lineno(5)))


def p_statement_draw_attr(p):
    """ statement : DRAW attr_list expr COMMA expr NEWLINE
                  | DRAW attr_list expr COMMA expr CO
    """
    p[0] = make_sentence('DRAW',
                         make_typecast(TYPE.integer, p[3], p.lineno(4)),
                         make_typecast(TYPE.integer, p[5], p.lineno(6)), p[2])


def p_statement_circle(p):
    """ statement : CIRCLE expr COMMA expr COMMA expr NEWLINE
                  | CIRCLE expr COMMA expr COMMA expr CO
    """
    p[0] = make_sentence('CIRCLE',
                         make_typecast(TYPE.byte_, p[2], p.lineno(3)),
                         make_typecast(TYPE.byte_, p[4], p.lineno(5)),
                         make_typecast(TYPE.byte_, p[6], p.lineno(7)))


def p_statement_circle_attr(p):
    """ statement : CIRCLE attr_list expr COMMA expr COMMA expr NEWLINE
                  | CIRCLE attr_list expr COMMA expr COMMA expr CO
    """
    p[0] = make_sentence('CIRCLE',
                         make_typecast(TYPE.byte_, p[3], p.lineno(4)),
                         make_typecast(TYPE.byte_, p[5], p.lineno(6)),
                         make_typecast(TYPE.byte_, p[7], p.lineno(8)), p[2])


def p_statement_cls(p):
    """ statement : CLS NEWLINE
                  | CLS CO
    """
    p[0] = make_sentence('CLS')


def p_statement_asm(p):
    """ statement : ASM NEWLINE
                  | ASM CO
    """
    p[0] = make_asm_sentence(p[1], p.lineno(1))


def p_statement_randomize(p):
    """ statement : RANDOMIZE NEWLINE
                  | RANDOMIZE CO
    """
    p[0] = make_sentence('RANDOMIZE',
                         make_number(0, lineno=p.lineno(1), type_=TYPE.ulong))


def p_statement_randomize_expr(p):
    """ statement : RANDOMIZE expr NEWLINE
                  | RANDOMIZE expr CO
    """
    p[0] = make_sentence('RANDOMIZE',
                         make_typecast(TYPE.ulong, p[2], p.lineno(1)))


def p_statement_beep(p):
    """ statement : BEEP expr COMMA expr NEWLINE
                  | BEEP expr COMMA expr CO
    """
    p[0] = make_sentence('BEEP', make_typecast(TYPE.float_, p[2], p.lineno(1)),
                         make_typecast(TYPE.float_, p[4], p.lineno(3)))


def p_statement_call(p):
    """ statement : ID arg_list NEWLINE
                  | ID arg_list CO
                  | ID NEWLINE
    """
    if len(p) == 3:
        p[0] = make_sub_call(p[1], p.lineno(1), make_arg_list(None))
    else:
        p[0] = make_sub_call(p[1], p.lineno(1), p[2])


def p_assignment(p):
    """ statement : lexpr expr CO
                  | lexpr expr NEWLINE
    """
    global LET_ASSIGNMENT

    LET_ASSIGNMENT = False  # Mark we're no longer using LET
    p[0] = None
    q = p[1:]
    i = 3

    if q[1] is None:
        return

    if isinstance(q[1], symbols.VAR) and q[1].class_ == CLASS.unknown:
        q[1] = SYMBOL_TABLE.access_var(q[1].name, p.lineno(3))

    q1class_ = q[1].class_ if isinstance(q[1], symbols.VAR) else CLASS.unknown
    variable = SYMBOL_TABLE.access_id(q[0], p.lineno(3), default_type=q[1].type_, default_class=q1class_)
    if variable is None:
        return  # HINT: This only happens if variable was not declared with DIM and --strict flag is in use

    if variable.class_ == CLASS.unknown:  # The variable is implicit
        variable.class_ = CLASS.var

    if variable.class_ not in (CLASS.var, CLASS.array):
        syntax_error(p.lineno(i), "Cannot assign a value to '%s'. It's not a variable" % variable.name)
        return

    if variable.class_ == CLASS.var and q1class_ == CLASS.array:
        syntax_error(p.lineno(i), 'Cannot assign an array to an escalar variable')
        return

    if variable.class_ == CLASS.array:
        if q1class_ != variable.class_:
            syntax_error(p.lineno(i), 'Cannot assign an escalar to an array variable')
            return

        if q[1].type_ != variable.type_:
            syntax_error(p.lineno(i), 'Arrays must have the same element type')
            return

        if variable.memsize != q[1].memsize:
            syntax_error(p.lineno(i), "Arrays '%s' and '%s' must have the same size" %
                         (variable.name, q[1].name))
            return

        if variable.count != q[1].count:
            warning(p.lineno(i), "Arrays '%s' and '%s' don't have the same number of dimensions" %
                    (variable.name, q[1].name))
        else:
            for b1, b2 in zip(variable.bounds, q[1].bounds):
                if b1.count != b2.count:
                    warning(p.lineno(i), "Arrays '%s' and '%s' don't have the same dimensions" %
                            (variable.name, q[1].name))
                    break

        # Array copy
        p[0] = make_sentence('ARRAYCOPY', variable, q[1])
        return

    expr = make_typecast(variable.type_, q[1], p.lineno(3))
    p[0] = make_sentence('LET', variable, expr)


def p_lexpr(p):
    """ lexpr : ID EQ
              | LET ID EQ
    """
    global LET_ASSIGNMENT

    LET_ASSIGNMENT = True  # Mark we're about to start a LET sentence

    if p[1] == 'LET':
        p[0] = p[2]
        i = 2
    else:
        p[0] = p[1]
        i = 1

    SYMBOL_TABLE.access_id(p[i], p.lineno(i))


def p_arr_assignment(p):
    """ statement : ID arg_list EQ expr CO
                  | ID arg_list EQ expr NEWLINE
                  | LET ID arg_list EQ expr CO
                  | LET ID arg_list EQ expr NEWLINE
    """
    q = p[1:]
    i = 2
    if q[0].upper() == 'LET':
        q = q[1:]
        i = 3

    if q[1] is None or q[3] is None:
        return  # There where errors

    p[0] = None
    # api.check.check_is_declared_strict(p.lineno(i - 1), q[0], classname='array')

    entry = SYMBOL_TABLE.access_call(q[0], p.lineno(i - 1))
    if entry is None:
        # variable = SYMBOL_TABLE.make_var(q[0], p.lineno(1), TYPE.string)
        # entry = SYMBOL_TABLE.get_id_entry(q[0])
        return

    if entry.class_ == CLASS.var and entry.type_ == TYPE.string:
        r = q[3]
        if r.type_ != TYPE.string:
            api.errmsg.syntax_error_expected_string(p.lineno(i - 1), r.type_)

        if len(q[1]) > 1:
            syntax_error(p.lineno(i), "Too many values. Expected only one.")
            return

        if len(q[1]) == 1:
            substr = (
                make_typecast(_TYPE(gl.STR_INDEX_TYPE), q[1][0].value, p.lineno(i)),
                make_typecast(_TYPE(gl.STR_INDEX_TYPE), q[1][0].value, p.lineno(i)))
        else:
            substr = (make_typecast(_TYPE(gl.STR_INDEX_TYPE),
                                    make_number(gl.MIN_STRSLICE_IDX,
                                                lineno=p.lineno(i)),
                                    p.lineno(i)),
                      make_typecast(_TYPE(gl.STR_INDEX_TYPE),
                                    make_number(gl.MAX_STRSLICE_IDX,
                                                lineno=p.lineno(i)),
                                    p.lineno(i)))

        p[0] = make_sentence('LETSUBSTR', entry, substr[0], substr[1], r)
        return

    arr = make_array_access(q[0], p.lineno(i), q[1])
    expr = make_typecast(arr.type_, q[3], p.lineno(i))
    p[0] = make_sentence('LETARRAY', arr, expr)


def p_str_assign(p):
    """ statement : ID substr EQ expr CO
                  | ID substr EQ expr NEWLINE
                  | LET ID substr EQ expr CO
                  | LET ID substr EQ expr NEWLINE
    """
    if p[1].upper() != 'LET':
        q = p[1]
        r = p[4]
        s = p[2]
        lineno = p.lineno(3)
    else:
        q = p[2]
        r = p[5]
        s = p[3]
        lineno = p.lineno(4)

    if q is None or s is None:
        p[0] = None
        return

    if r.type_ != TYPE.string:
        api.errmsg.syntax_error_expected_string(lineno, r.type_)

    entry = SYMBOL_TABLE.access_var(q, lineno, default_type=TYPE.string)
    if entry is None:
        p[0] = None
        return

    p[0] = make_sentence('LETSUBSTR', entry, s[0], s[1], r)


def p_goto(p):
    """ statement : goto NUMBER CO
                  | goto NUMBER NEWLINE
                  | goto ID CO
                  | goto ID NEWLINE
    """
    if isinstance(p[2], float):
        if p[2] == int(p[2]):
            id_ = str(int(p[2]))
        else:
            syntax_error(p.lineno(1), 'Line numbers must be integers.')
            p[0] = None
            return
    else:
        id_ = p[2]

    entry = SYMBOL_TABLE.access_label(id_, p.lineno(2))
    if entry is not None:
        p[0] = make_sentence(p[1].upper(), entry)
    else:
        p[0] = None


def p_go(p):
    """ goto : GO TO
             | GO SUB
             | GOTO
             | GOSUB
    """
    p[0] = p[1]
    if p[0] == 'GO':
        p[0] += p[2]


def p_endif(p):
    """ endif : END IF
              | LABEL END IF
    """
    if p[1] == 'END':
        p[0] = make_nop()
    else:
        p[0] = make_label(p[1], p.lineno(1))


def p_if_sentence(p):
    """ statement : IF expr then program endif CO
                  | IF expr then program endif NEWLINE
    """
    if is_null(p[4]):
        warning(p.lineno(1), 'Useless empty IF ignored')
        p[0] = p[5]
        return

    if is_number(p[2]):
        api.errmsg.warning_condition_is_always(p.lineno(1), bool(p[2].value))
        if OPTIONS.optimization.value > 0:
            if not p[2].value:
                p[0] = p[5]
                return
            else:
                p[0] = make_block(p[4], p[5])
                return

    p[0] = make_sentence('IF', p[2], make_block(p[4], p[5]))


def p_if_elseif(p):
    """ statement : IF expr then program elseiflist CO
                  | IF expr then program elseiflist NEWLINE
    """
    if is_null(p[4], p[5]):
        p[0] = make_nop()
        return

    if is_number(p[2]):
        api.errmsg.warning_condition_is_always(p.lineno(1), bool(p[2].value))
        if OPTIONS.optimization.value > 0:
            if not p[2].value:
                p[0] = p[5]
                return

    if not p[4]:  # Empty block?
        p[4].appendChild(make_nop())

    p[0] = make_sentence('IF', p[2], p[4], p[5])


def p_elseif_list(p):
    """ elseiflist : ELSEIF expr then program endif
                   | LABEL ELSEIF expr then program endif
    """
    if p[1] == 'ELSEIF':
        p1 = make_nop()  # No label
        p2 = p[2]
        p4 = p[4]
        p5 = p[5]
    else:
        p1 = make_label(p[1], p.lineno(1))
        p2 = p[3]
        p4 = p[5]
        p5 = p[6]

    if is_null(p4):
        warning(p.lineno(1), 'Useless empty ELSEIF ignored')
        p[0] = make_block(p1, p5)
        return

    if is_number(p2):
        api.errmsg.warning_condition_is_always(p.lineno(1), bool(p2.value))
        if OPTIONS.optimization.value > 0:
            if not p2.value:
                p[0] = make_block(p1, p5)
                return

    p[0] = make_block(p1, make_sentence('IF', p2, make_block(p4, p5)))


def p_elseif_elseiflist(p):
    """ elseiflist : ELSEIF expr then program elseiflist
                   | LABEL ELSEIF expr then program elseiflist
    """
    if p[1] == 'ELSEIF':
        p1 = make_nop()
        p2 = p[2]
        p4 = p[4]
        p5 = p[5]
    else:
        p1 = make_label(p[1], p.lineno(1))
        p2 = p[3]
        p4 = p[5]
        p5 = p[6]

    if is_null(p4, p5):
        p[0] = make_block(p1, p5)
        return

    if is_number(p2) and p2.value == 0:
        api.errmsg.warning_condition_is_always(p.lineno(1))
        if OPTIONS.optimization.value > 0:
            p[0] = make_block(p1, p5)
            return

    p[0] = make_block(p1, make_sentence('IF', p2, p4, p5))


def p_else(p):
    """ else : ELSE
             | LABEL ELSE
    """
    if p[1] == 'ELSE':
        p[0] = make_nop()
    else:
        p[0] = make_label(p[1], p.lineno(1))


def p_if_else(p):
    """ statement : IF expr then program else program endif CO
                  | IF expr then program else program endif NEWLINE
    """
    if is_null(p[4], p[6]):
        warning(p.lineno(1), 'Useless empty IF ignored')
        p[0] = p[7]
        return

    if is_number(p[2]):
        api.errmsg.warning_condition_is_always(p.lineno(1), bool(p[2].value))
        if not p[2].value:
            p[0] = make_block(p[6], p[7])
            return
        else:
            p[0] = make_block(p[4], p[7])
            return

    if is_null(p[4]):
        p[2] = make_unary(p.lineno(1), 'NOT', p[2], lambda x: not x)
        p[0] = make_sentence('IF', p[2], make_block(p[5], p[6], p[7]))

    if is_null(p[6]):
        p[6] = make_nop()

    p[0] = make_sentence('IF', p[2], p[4], make_block(p[5], p[6], p[7]))


def p_if_elseif_else(p):
    """ statement : IF expr then program elseif_elselist program endif CO
                  | IF expr then program elseif_elselist program endif NEWLINE
    """
    if is_number(p[2]) and p[2].value == 0:  # Always false?
        api.errmsg.warning_condition_is_always(p.lineno(1))
        if OPTIONS.optimization.value > 0:
            if is_null(p[5]):  # If no else part, return last parts
                p[0] = make_block(p[6], p[7])
                return

            p[5][1].children[-1].appendChild(make_block(p[6], p[7]))
            p[0] = p[5]
            return

    if is_null(p[5]):  # Normal IF/THEN/ELSE
        p[0] = make_sentence('IF', p[2], p[4], make_block(p[6], p[7]))
        return

    p[5][1].children[-1].appendChild(make_block(p[6], p[7]))
    p[0] = make_sentence('IF', p[2], p[4], p[5][0])


def p_elseif_elselist_else(p):
    """ elseif_elselist : ELSEIF expr then program else
                        | LABEL ELSEIF expr then program else
    """
    if p[1] == 'ELSEIF':
        p1 = make_nop()
        p2 = p[2]
        p4 = p[4]
        p5 = p[5]
    else:
        p1 = make_label(p[1], p.lineno(1))
        p2 = p[3]
        p4 = p[5]
        p5 = p[6]

    if is_number(p2):
        api.errmsg.warning_condition_is_always(p.lineno(1), bool(p2.value))
        if OPTIONS.optimization.value > 0:
            if not p2.value:
                p[0] = p1
                return

    # p[6] must be added in the rule above
    last = make_block(p1, make_sentence('IF', p2, make_block(p4, p5)))
    p[0] = (last, last)


def p_elseif_elselist(p):
    """ elseif_elselist : ELSEIF expr then program elseif_elselist
                        | LABEL ELSEIF expr then program elseif_elselist
    """
    if p[1] == 'ELSEIF':
        p1 = make_nop()
        p2 = p[2]
        p4 = p[4]
        p5 = p[5]
    else:
        p1 = make_label(p[1], p.lineno(1))
        p2 = p[3]
        p4 = p[5]
        p5 = p[6]

    if is_number(p2) and p2.value == 0:
        api.errmsg.warning_condition_is_always(p.lineno(1))
        if OPTIONS.optimization.value > 0:
            last = p5[1]
            p[0] = (make_block(p1, p5[0]), last)
            return

    node = make_sentence('IF', p2, p4, p5[0])
    p[0] = (make_block(p1, node), p5[1])


def p_then(p):
    """ then :
             | THEN
    """


def p_for_sentence(p):
    """ statement : for_start program label_next CO
                  | for_start program label_next NEWLINE
    """
    p[0] = p[1]
    if is_null(p[0]):
        return
    p[1].appendChild(make_block(p[2], p[3]))
    gl.LOOPS.pop()


def p_next(p):
    """ label_next : LABEL NEXT
                   | NEXT
    """
    if p[1] == 'NEXT':
        p[0] = make_nop()
    else:
        p[0] = make_label(p[1], p.lineno(1))


def p_next1(p):
    """ label_next : LABEL NEXT ID
                   | NEXT ID
    """
    if p[1] == 'NEXT':
        p1 = make_nop()
        p3 = p[2]
    else:
        p1 = make_label(p[1], p.lineno(1))
        p3 = p[3]

    if p3 != gl.LOOPS[-1][1]:
        api.errmsg.syntax_error_wrong_for_var(p.lineno(2), gl.LOOPS[-1][1], p3)
        p[0] = make_nop()
        return

    p[0] = p1


def p_end(p):
    """ statement : END expr CO
                  | END expr NEWLINE
                  | END CO
                  | END NEWLINE
    """
    q = p[2]
    if not isinstance(q, Symbol):
        q = make_number(0, lineno=p.lineno(1))
    p[0] = make_sentence('END', q)


def p_error_raise(p):
    """ statement : ERROR expr CO
                  | ERROR expr NEWLINE
    """
    q = make_number(1, lineno=p.lineno(3))
    r = make_binary(p.lineno(1), 'MINUS',
                    make_typecast(TYPE.ubyte, p[2], p.lineno(1)), q,
                    lambda x, y: x - y)
    p[0] = make_sentence('ERROR', r)


def p_stop_raise(p):
    """ statement : STOP expr CO
                  | STOP expr NEWLINE
                  | STOP CO
                  | STOP NEWLINE
    """
    q = p[2]
    if not isinstance(q, Symbol):
        q = make_number(9, lineno=p.lineno(1))

    z = make_number(1, lineno=p.lineno(1))
    r = make_binary(p.lineno(1), 'MINUS',
                    make_typecast(TYPE.ubyte, q, p.lineno(1)), z,
                    lambda x, y: x - y)
    p[0] = make_sentence('STOP', r)


def p_for_sentence_start(p):
    """ for_start : FOR ID EQ expr TO expr step
    """
    # api.check.check_is_declared(p.lineno(2), p[2])
    gl.LOOPS.append(('FOR', p[2]))
    p[0] = None

    if p[4] is None or p[6] is None or p[7] is None:
        return

    if is_number([p[4], p[6], p[7]]):
        if p[4].value != p[6].value and p[7].value == 0:
            warning(p.lineno(5), 'STEP value is 0 and FOR might loop forever')

        if p[4].value > p[6].value and p[7].value > 0:
            warning(p.lineno(5), 'FOR start value is greater than end. This FOR loop is useless')
            if OPTIONS.optimizations > 0:
                return

        if p[4].value < p[6].value and p[7].value < 0:
            warning(p.lineno(2), 'FOR start value is lower than end. This FOR loop is useless')
            if OPTIONS.optimizations > 0:
                return

    id_type = common_type(common_type(p[4], p[6]), p[7])

    variable = SYMBOL_TABLE.access_var(p[2], p.lineno(2), default_type=id_type)
    if variable is None:
        return

    variable.accessed = True
    expr1 = make_typecast(variable.type_, p[4], p.lineno(3))
    expr2 = make_typecast(variable.type_, p[6], p.lineno(5))
    expr3 = make_typecast(variable.type_, p[7], p.lexer.lineno)

    p[0] = make_sentence('FOR', variable, expr1, expr2, expr3)


def p_step(p):
    """ step :
    """
    p[0] = make_number(1, lineno=p.lexer.lineno)


def p_step_expr(p):
    """ step : STEP expr
    """
    p[0] = p[2]


def p_loop(p):
    """ label_loop : LABEL LOOP
                   | LOOP
    """
    if p[1] == 'LOOP':
        p[0] = None
    else:
        p[0] = make_label(p[1], p.lineno(1))


def p_do_loop(p):
    """ statement : do_start program label_loop CO
                  | do_start program label_loop NEWLINE
                  | do_start label_loop CO
                  | do_start label_loop NEWLINE
                  | DO label_loop CO
                  | DO label_loop NEWLINE
    """
    if len(p) > 4:
        q = make_block(p[2], p[3])
    else:
        q = p[2]

    if p[1] == 'DO':
        gl.LOOPS.append(('DO',))

    if q is None:
        warning(p.lineno(1), 'Infinite empty loop')

    # An infinite loop and no warnings
    p[0] = make_sentence('DO_LOOP', q)
    gl.LOOPS.pop()


def p_do_loop_until(p):
    """ statement : do_start program label_loop UNTIL expr CO
                  | do_start program label_loop UNTIL expr NEWLINE
                  | do_start label_loop UNTIL expr CO
                  | do_start label_loop UNTIL expr NEWLINE
                  | DO label_loop UNTIL expr NEWLINE
                  | DO label_loop UNTIL expr CO
    """
    if len(p) > 6:
        q = make_block(p[2], p[3])
        r = p[5]
    else:
        q = p[2]
        r = p[4]

    if p[1] == 'DO':
        gl.LOOPS.append(('DO',))

    p[0] = make_sentence('DO_UNTIL', r, q)

    gl.LOOPS.pop()
    if is_number(r):
        api.errmsg.warning_condition_is_always(p.lineno(3), bool(r.value))
    if q is None:
        api.errmsg.warning_empty_loop(p.lineno(3))


def p_do_loop_while(p):
    """ statement : do_start program label_loop WHILE expr CO
                  | do_start program label_loop WHILE expr NEWLINE
                  | do_start label_loop WHILE expr CO
                  | do_start label_loop WHILE expr NEWLINE
                  | DO label_loop WHILE expr NEWLINE
                  | DO label_loop WHILE expr CO
    """
    if len(p) > 6:
        q = make_block(p[2], p[3])
        r = p[5]
    else:
        q = p[2]
        r = p[4]

    if p[1] == 'DO':
        gl.LOOPS.append(('DO',))

    p[0] = make_sentence('DO_WHILE', r, q)
    gl.LOOPS.pop()

    if is_number(r):
        api.errmsg.warning_condition_is_always(p.lineno(3), bool(r.value))
    if q is None:
        api.errmsg.warning_empty_loop(p.lineno(3))


def p_do_while_loop(p):
    """ statement : do_while_start program LOOP CO
                  | do_while_start program LOOP NEWLINE
                  | do_while_start LOOP CO
                  | do_while_start LOOP NEWLINE
    """
    r = p[1]
    q = p[2]
    if q == 'LOOP':
        q = None

    p[0] = make_sentence('WHILE_DO', r, q)
    gl.LOOPS.pop()

    if is_number(r):
        api.errmsg.warning_condition_is_always(p.lineno(2), bool(r.value))


def p_do_until_loop(p):
    """ statement : do_until_start program LOOP CO
                  | do_until_start program LOOP NEWLINE
                  | do_until_start LOOP CO
                  | do_until_start LOOP NEWLINE
    """
    r = p[1]
    q = p[2]
    if q == 'LOOP':
        q = None

    p[0] = make_sentence('UNTIL_DO', r, q)
    gl.LOOPS.pop()

    if is_number(r):
        api.errmsg.warning_condition_is_always(p.lineno(2), bool(r.value))


def p_do_while_start(p):
    """ do_while_start : DO WHILE expr CO
                       | DO WHILE expr NEWLINE
    """
    p[0] = p[3]
    gl.LOOPS.append(('DO',))


def p_do_until_start(p):
    """ do_until_start : DO UNTIL expr CO
                       | DO UNTIL expr NEWLINE
    """
    p[0] = p[3]
    gl.LOOPS.append(('DO',))


def p_do_start(p):
    """ do_start : DO CO
                 | DO NEWLINE
    """
    gl.LOOPS.append(('DO',))


def p_label_end_while(p):
    """ label_end_while : LABEL END WHILE
                  | LABEL WEND
                  | END WHILE
                  | WEND
    """
    if p[1] in ('WEND', 'END'):
        p[0] = None
    else:
        p[0] = make_label(p[1], p.lineno(1))


def p_while_sentence(p):
    """ statement : while_start program label_end_while CO
                  | while_start program label_end_while NEWLINE
                  | while_start label_end_while CO
                  | while_start label_end_while NEWLINE
    """
    gl.LOOPS.pop()

    if len(p) > 4:
        q = make_block(p[2], p[3])
    else:
        q = p[2]

    if is_number(p[1]):
        if p[1].value == 0:
            api.errmsg.warning_condition_is_always(p[1].lineno)
            if OPTIONS.optimization.value > 0:
                warning(p[1].lineno, "Loop has been ignored")
                p[0] = None
            else:
                p[0] = make_sentence('WHILE', p[1], q)
        else:
            p[0] = make_sentence('WHILE', p[1], q)
            if q is None:
                warning(p[1].lineno, "Condition is always true and leads to an infinite loop.")
            else:
                warning(p[1].lineno, "Condition is always true and might lead to an infinite loop.")
    else:
        p[0] = make_sentence('WHILE', p[1], q)


def p_while_start(p):
    """ while_start : WHILE expr
    """
    p[0] = p[2]
    gl.LOOPS.append(('WHILE',))


def p_exit(p):
    """ statement : EXIT WHILE CO
                  | EXIT WHILE NEWLINE
                  | EXIT DO CO
                  | EXIT DO NEWLINE
                  | EXIT FOR CO
                  | EXIT FOR NEWLINE
    """
    q = p[2]
    p[0] = make_sentence('EXIT_%s' % q)

    for i in gl.LOOPS:
        if q == i[0]:
            return

    syntax_error(p.lineno(1), 'Syntax Error: EXIT %s out of loop' % q)


def p_continue(p):
    """ statement : CONTINUE WHILE CO
                  | CONTINUE WHILE NEWLINE
                  | CONTINUE DO CO
                  | CONTINUE DO NEWLINE
                  | CONTINUE FOR CO
                  | CONTINUE FOR NEWLINE
    """
    q = p[2]
    p[0] = make_sentence('CONTINUE_%s' % q)

    for i in gl.LOOPS:
        if q == i[0]:
            return

    syntax_error(p.lineno(1), 'Syntax Error: CONTINUE %s out of loop' % q)


def p_print_sentence(p):
    """ statement : PRINT print_list CO
                  | PRINT print_list NEWLINE
    """
    global PRINT_IS_USED

    p[0] = p[2]
    PRINT_IS_USED = True


def p_print_list_expr(p):
    """ print_elem : expr
                   | print_at
                   | print_tab
                   | attr
                   | BOLD expr
                   | ITALIC expr
    """
    if p[1] in ('BOLD', 'ITALIC'):
        p[0] = make_sentence(p[1] + '_TMP',
                             make_typecast(TYPE.ubyte, p[2], p.lineno(1)))
    else:
        p[0] = p[1]


def p_attr_list(p):
    """ attr_list : attr SC
    """
    p[0] = p[1]


def p_attr_list_list(p):
    """ attr_list : attr_list attr SC
    """
    p[0] = make_block(p[1], p[2])


def p_attr(p):
    """ attr : OVER expr
             | INVERSE expr
             | INK expr
             | PAPER expr
             | BRIGHT expr
             | FLASH expr
    """
    # ATTR_LIST are used by drawing commands: PLOT, DRAW, CIRCLE
    # BOLD and ITALIC are ignored by them, so we put them out of the
    # attr definition so something like DRAW BOLD 1; .... will raise
    # a syntax error
    p[0] = make_sentence(p[1] + '_TMP',
                         make_typecast(TYPE.ubyte, p[2], p.lineno(1)))


def p_print_list_epsilon(p):
    """ print_elem :
    """
    p[0] = None


def p_print_list_elem(p):
    """ print_list : print_elem
    """
    p[0] = make_sentence('PRINT', p[1])
    p[0].eol = True


def p_print_list(p):
    """ print_list : print_list SC print_elem
    """
    p[0] = p[1]
    p[0].eol = (p[3] is not None)

    if p[3] is not None:
        p[0].appendChild(p[3])


def p_print_list_comma(p):
    """ print_list : print_list COMMA print_elem
    """
    p[0] = p[1]
    p[0].eol = (p[3] is not None)
    p[0].appendChild(make_sentence('PRINT_COMMA'))

    if p[3] is not None:
        p[0].appendChild(p[3])


def p_print_list_at(p):
    """ print_at : AT expr COMMA expr
    """
    p[0] = make_sentence('PRINT_AT',
                         make_typecast(TYPE.ubyte, p[2], p.lineno(1)),
                         make_typecast(TYPE.ubyte, p[4], p.lineno(3)))


def p_print_list_tab(p):
    """ print_tab : TAB expr
    """
    p[0] = make_sentence('PRINT_TAB',
                         make_typecast(TYPE.ubyte, p[2], p.lineno(1)))


def p_return(p):
    """ statement : RETURN CO
                  | RETURN NEWLINE
    """
    if not FUNCTION_LEVEL:  # At less one level, otherwise, this return is from a GOSUB
        p[0] = make_sentence('RETURN')
        return

    if FUNCTION_LEVEL[-1].kind != 'sub':
        syntax_error(p.lineno(1), 'Syntax Error: Functions must RETURN a value, or use EXIT FUNCTION instead.')
        p[0] = None
        return

    p[0] = make_sentence('RETURN', FUNCTION_LEVEL[-1])


def p_return_expr(p):
    """ statement : RETURN expr CO
                  | RETURN expr NEWLINE
    """
    if not FUNCTION_LEVEL:  # At less one level
        syntax_error(p.lineno(1), 'Syntax Error: Returning value out of FUNCTION')
        p[0] = None
        return

    if FUNCTION_LEVEL[-1].kind is None:  # This function was not correctly declared.
        p[0] = None
        return

    if FUNCTION_LEVEL[-1].kind != 'function':
        syntax_error(p.lineno(1), 'Syntax Error: SUBs cannot return a value')
        p[0] = None
        return

    if is_numeric(p[2]) and FUNCTION_LEVEL[-1].type_ == TYPE.string:
        syntax_error(p.lineno(2), 'Type Error: Function must return a string, not a numeric value')
        p[0] = None
        return

    if not is_numeric(p[2]) and FUNCTION_LEVEL[-1].type_ != TYPE.string:
        syntax_error(p.lineno(2), 'Type Error: Function must return a numeric value, not a string')
        p[0] = None
        return

    p[0] = make_sentence('RETURN', FUNCTION_LEVEL[-1],
                         make_typecast(FUNCTION_LEVEL[-1].type_, p[2],
                                       p.lineno(1)))


def p_pause(p):
    """ statement : PAUSE expr CO
                  | PAUSE expr NEWLINE
    """
    p[0] = make_sentence('PAUSE',
                         make_typecast(TYPE.uinteger, p[2], p.lineno(1)))


def p_poke(p):
    """ statement : POKE expr COMMA expr CO
                  | POKE expr COMMA expr NEWLINE
                  | POKE LP expr COMMA expr RP CO
                  | POKE LP expr COMMA expr RP NEWLINE
    """
    i = 2 if isinstance(p[2], Symbol) else 3
    p[0] = make_sentence('POKE',
                         make_typecast(TYPE.uinteger, p[i], p.lineno(i + 1)),
                         make_typecast(TYPE.ubyte, p[i + 2], p.lineno(i + 3)))


def p_poke2(p):
    """ statement : POKE numbertype expr COMMA expr CO
                  | POKE numbertype expr COMMA expr NEWLINE
                  | POKE LP numbertype expr COMMA expr RP CO
                  | POKE LP numbertype expr COMMA expr RP NEWLINE
    """
    i = 2 if isinstance(p[2], Symbol) else 3
    p[0] = make_sentence('POKE',
                         make_typecast(TYPE.uinteger, p[i + 1],
                                       p.lineno(i + 2)),
                         make_typecast(p[i], p[i + 3], p.lineno(i + 4)))


def p_poke3(p):
    """ statement : POKE numbertype COMMA expr COMMA expr CO
                  | POKE numbertype COMMA expr COMMA expr NEWLINE
                  | POKE LP numbertype COMMA expr COMMA expr RP CO
                  | POKE LP numbertype COMMA expr COMMA expr RP NEWLINE
    """
    i = 2 if isinstance(p[2], Symbol) else 3
    p[0] = make_sentence('POKE',
                         make_typecast(TYPE.uinteger, p[i + 2],
                                       p.lineno(i + 3)),
                         make_typecast(p[i], p[i + 4], p.lineno(i + 5)))


def p_out(p):
    """ statement : OUT expr COMMA expr CO
                  | OUT expr COMMA expr NEWLINE
    """
    p[0] = make_sentence('OUT',
                         make_typecast(TYPE.uinteger, p[2], p.lineno(3)),
                         make_typecast(TYPE.ubyte, p[4], p.lineno(5)))


def p_simple_instruction(p):
    """ statement : ITALIC expr CO
                  | ITALIC expr NEWLINE
                  | BOLD expr CO
                  | BOLD expr NEWLINE
                  | INK expr CO
                  | INK expr NEWLINE
                  | PAPER expr CO
                  | PAPER expr NEWLINE
                  | BRIGHT expr CO
                  | BRIGHT expr NEWLINE
                  | FLASH expr CO
                  | FLASH expr NEWLINE
                  | OVER expr CO
                  | OVER expr NEWLINE
                  | INVERSE expr CO
                  | INVERSE expr NEWLINE
    """
    p[0] = make_sentence(p[1], make_typecast(TYPE.ubyte, p[2], p.lineno(3)))


def p_save_code(p):
    """ statement : SAVE expr CODE expr COMMA expr CO
                  | SAVE expr CODE expr COMMA expr NEWLINE
                  | SAVE expr ID NEWLINE
                  | SAVE expr ID CO
    """
    if p[2].type_ != TYPE.string:
        api.errmsg.syntax_error_expected_string(p.lineno(1), p[2].type_)

    if len(p) == 5:
        if p[3].upper() not in ('SCREEN', 'SCREEN$'):
            syntax_error(p.lineno(3), 'Unexpected "%s" ID. Expected "SCREEN$" instead' % p[3])
            return None
        else:
            # ZX Spectrum screen start + length
            # This should be stored in a architecture-dependant file
            start = make_number(16384, lineno=p.lineno(1))
            length = make_number(6912, lineno=p.lineno(1))
    else:
        start = p[4]
        length = p[6]

    p[0] = make_sentence(p[1], p[2], start, length)


def p_save_data(p):
    """ statement : SAVE expr DATA CO
                  | SAVE expr DATA NEWLINE
                  | SAVE expr DATA ID CO
                  | SAVE expr DATA ID NEWLINE
                  | SAVE expr DATA ID LP RP CO
                  | SAVE expr DATA ID LP RP NEWLINE
    """
    if p[2].type_ != TYPE.string:
        api.errmsg.syntax_error_expected_string(p.lineno(1), p[2].type_)

    if len(p) != 5:
        entry = SYMBOL_TABLE.access_id(p[4], p.lineno(4))
        if entry is None:
            p[0] = None
            return

        entry.accessed = True
        access = entry
        start = make_unary(p.lineno(4), 'ADDRESS', access, type_=TYPE.uinteger)

        if entry.class_ == CLASS.array:
            length = make_number(entry.memsize, lineno=p.lineno(4))
        else:
            length = make_number(entry.type_.size, lineno=p.lineno(4))
    else:
        access = SYMBOL_TABLE.access_id('.ZXBASIC_USER_DATA', p.lineno(4))
        start = make_unary(p.lineno(4), 'ADDRESS', access, type_=TYPE.uinteger)

        access = SYMBOL_TABLE.access_id('.ZXBASIC_USER_DATA_LEN', p.lineno(4))
        length = make_unary(p.lineno(4), 'ADDRESS', access,
                            type_=TYPE.uinteger)

    p[0] = make_sentence(p[1], p[2], start, length)


def p_load_or_verify(p):
    """ load_or_verify : LOAD
                       | VERIFY
    """
    p[0] = p[1]


def p_load_code(p):
    """ statement : load_or_verify expr ID CO
                  | load_or_verify expr CODE CO
                  | load_or_verify expr CODE expr CO
                  | load_or_verify expr CODE expr COMMA expr CO
                  | load_or_verify expr ID NEWLINE
                  | load_or_verify expr CODE NEWLINE
                  | load_or_verify expr CODE expr NEWLINE
                  | load_or_verify expr CODE expr COMMA expr NEWLINE
    """
    if p[2].type_ != TYPE.string:
        api.errmsg.syntax_error_expected_string(p.lineno(3), p[2].type_)

    if len(p) == 5:
        if p[3].upper() not in ('SCREEN', 'SCREEN$', 'CODE'):
            syntax_error(p.lineno(3), 'Unexpected "%s" ID. Expected "SCREEN$" instead' % p[3])
            return None
        else:
            if p[3].upper() == 'CODE':  # LOAD "..." CODE
                start = make_number(0, lineno=p.lineno(3))
                length = make_number(0, lineno=p.lineno(3))
            else:  # SCREEN$
                start = make_number(16384, lineno=p.lineno(3))
                length = make_number(6912, lineno=p.lineno(3))
    else:
        start = make_typecast(TYPE.uinteger, p[4], p.lineno(3))

        if len(p) == 6:
            length = make_number(0, lineno=p.lineno(3))
        else:
            length = make_typecast(TYPE.uinteger, p[6], p.lineno(5))

    p[0] = make_sentence(p[1], p[2], start, length)


def p_load_data(p):
    """ statement : load_or_verify expr DATA CO
                  | load_or_verify expr DATA NEWLINE
                  | load_or_verify expr DATA ID CO
                  | load_or_verify expr DATA ID NEWLINE
                  | load_or_verify expr DATA ID LP RP CO
                  | load_or_verify expr DATA ID LP RP NEWLINE
    """
    if p[2].type_ != TYPE.string:
        api.errmsg.syntax_error_expected_string(p.lineno(1), p[2].type_)

    if len(p) != 5:
        entry = SYMBOL_TABLE.access_id(p[4], p.lineno(4))
        if entry is None:
            p[0] = None
            return

        entry.accessed = True
        start = make_unary(p.lineno(4), 'ADDRESS', entry, type_=TYPE.uinteger)

        if entry.class_ == CLASS.array:
            length = make_number(entry.memsize, lineno=p.lineno(4))
        else:
            length = make_number(entry.type_.size, lineno=p.lineno(4))
    else:
        entry = SYMBOL_TABLE.access_id('.ZXBASIC_USER_DATA', p.lineno(4))
        start = make_unary(p.lineno(4), 'ADDRESS', entry, type_=TYPE.uinteger)

        entry = SYMBOL_TABLE.access_id('.ZXBASIC_USER_DATA_LEN', p.lineno(4))
        length = make_unary(p.lineno(4), 'ADDRESS', entry,
                            type_=TYPE.uinteger)

    p[0] = make_sentence(p[1], p[2], start, length)


def p_numbertype(p):
    """ numbertype : BYTE
                   | UBYTE
                   | INTEGER
                   | UINTEGER
                   | LONG
                   | ULONG
                   | FIXED
                   | FLOAT
    """
    p[0] = make_type(p[1].lower(), p.lineno(1))


def p_expr_plus_expr(p):
    """ expr : expr PLUS expr
    """
    p[0] = make_binary(p.lineno(2), 'PLUS', p[1], p[3], lambda x, y: x + y)


def p_expr_minus_expr(p):
    """ expr : expr MINUS expr
    """
    p[0] = make_binary(p.lineno(2), 'MINUS', p[1], p[3], lambda x, y: x - y)


def p_expr_mul_expr(p):
    """ expr : expr MUL expr
    """
    p[0] = make_binary(p.lineno(2), 'MUL', p[1], p[3], lambda x, y: x * y)


def p_expr_div_expr(p):
    """ expr : expr DIV expr
    """
    p[0] = make_binary(p.lineno(2), 'DIV', p[1], p[3], lambda x, y: x / y)


def p_expr_mod_expr(p):
    """ expr : expr MOD expr
    """
    p[0] = make_binary(p.lineno(2), 'MOD', p[1], p[3], lambda x, y: x % y)


def p_expr_pow_expr(p):
    """ expr : expr POW expr
    """
    p[0] = make_binary(p.lineno(2), 'POW',
                       make_typecast(TYPE.float_, p[1], p.lineno(2)),
                       make_typecast(TYPE.float_, p[3], p.lexer.lineno),
                       lambda x, y: x ** y)


def p_expr_shl_expr(p):
    """ expr : expr SHL expr
    """
    if p[1] is None or p[3] is None:
        p[0] = None
        return

    if p[1].type_ in (TYPE.float_, TYPE.fixed):
        p[1] = make_typecast(TYPE.ulong, p[1], p.lineno(2))

    p[0] = make_binary(p.lineno(2), 'SHL', p[1],
                       make_typecast(TYPE.ubyte, p[3], p.lineno(2)),
                       lambda x, y: x << y)


def p_expr_shr_expr(p):
    """ expr : expr SHR expr
    """
    if p[1] is None or p[3] is None:
        p[0] = None
        return

    if p[1].type_ in (TYPE.float_, TYPE.fixed):
        p[1] = make_typecast(TYPE.ulong, p[1], p.lineno(2))

    p[0] = make_binary(p.lineno(2), 'SHR', p[1],
                       make_typecast(TYPE.ubyte, p[3], p.lineno(2)),
                       lambda x, y: x >> y)


def p_minus_expr(p):
    """ expr : MINUS expr %prec UMINUS
    """
    p[0] = make_unary(p.lineno(1), 'MINUS', p[2], lambda x: -x)


def p_expr_EQ_expr(p):
    """ expr : expr EQ expr
    """
    p[0] = make_binary(p.lineno(2), 'EQ', p[1], p[3], lambda x, y: x == y)


def p_expr_LT_expr(p):
    """ expr : expr LT expr
    """
    p[0] = make_binary(p.lineno(2), 'LT', p[1], p[3], lambda x, y: x < y)


def p_expr_LE_expr(p):
    """ expr : expr LE expr
    """
    p[0] = make_binary(p.lineno(2), 'LE', p[1], p[3], lambda x, y: x <= y)


def p_expr_GT_expr(p):
    """ expr : expr GT expr
    """
    p[0] = make_binary(p.lineno(2), 'GT', p[1], p[3], lambda x, y: x > y)


def p_expr_GE_expr(p):
    """ expr : expr GE expr
    """
    p[0] = make_binary(p.lineno(2), 'GE', p[1], p[3], lambda x, y: x >= y)


def p_expr_NE_expr(p):
    """ expr : expr NE expr
    """
    p[0] = make_binary(p.lineno(2), 'NE', p[1], p[3], lambda x, y: x != y)


def p_expr_OR_expr(p):
    """ expr : expr OR expr
    """
    p[0] = make_binary(p.lineno(2), 'OR', p[1], p[3], lambda x, y: x or y)


def p_expr_BOR_expr(p):
    """ expr : expr BOR expr
    """
    p[0] = make_binary(p.lineno(2), 'BOR', p[1], p[3], lambda x, y: x | y)


def p_expr_XOR_expr(p):
    """ expr : expr XOR expr
    """
    p[0] = make_binary(p.lineno(2), 'XOR', p[1], p[3], lambda x, y: (x and not y) or (not x and y))


def p_expr_BXOR_expr(p):
    """ expr : expr BXOR expr
    """
    p[0] = make_binary(p.lineno(2), 'BXOR', p[1], p[3], lambda x, y: x ^ y)


def p_expr_AND_expr(p):
    """ expr : expr AND expr
    """
    p[0] = make_binary(p.lineno(2), 'AND', p[1], p[3], lambda x, y: x and y)


def p_expr_BAND_expr(p):
    """ expr : expr BAND expr
    """
    p[0] = make_binary(p.lineno(2), 'BAND', p[1], p[3], lambda x, y: x & y)


def p_NOT_expr(p):
    """ expr : NOT expr
    """
    p[0] = make_unary(p.lineno(1), 'NOT', p[2], lambda x: not x)


def p_BNOT_expr(p):
    """ expr : BNOT expr
    """
    p[0] = make_unary(p.lineno(1), 'BNOT', p[2], lambda x: ~x)


def p_lp_expr_rp(p):
    """ expr : LP expr RP
    """
    p[0] = p[2]


def p_cast(p):
    """ expr : CAST LP numbertype COMMA expr RP
    """
    p[0] = make_typecast(p[3], p[5], p.lineno(6))


def p_number_expr(p):
    """ expr : NUMBER
    """
    p[0] = make_number(p[1], lineno=p.lineno(1))


def p_expr_PI(p):
    """ expr : PI
    """
    p[0] = make_number(PI, lineno=p.lineno(1), type_=TYPE.float_)


def p_number_line(p):
    """ expr : __LINE__
    """
    p[0] = make_number(p.lineno(1), lineno=p.lineno(1))


def p_expr_string(p):
    """ expr : string
    """
    p[0] = p[1]


def p_string_func_call(p):
    """ string : func_call substr
    """
    p[0] = make_strslice(p.lineno(1), p[1], p[2][0], p[2][1])


def p_string_str(p):
    """ string : STRC
    """
    p[0] = symbols.STRING(p[1], p.lineno(1))


def p_string_lprp(p):
    """ string : string LP RP
    """
    p[0] = p[1]


def p_string_lp_expr_rp(p):
    """ string : string LP expr RP
    """
    p[0] = make_strslice(p.lineno(2), p[1], p[3], p[3])


def p_expr_id_substr(p):
    """ string : ID substr
    """
    entry = SYMBOL_TABLE.access_var(p[1], p.lineno(1), default_type=TYPE.string)
    p[0] = None
    if entry is None:
        return

    entry.accessed = True
    p[0] = make_strslice(p.lineno(1), entry, p[2][0], p[2][1])


def p_string_substr(p):
    """ string : string substr
    """
    p[0] = make_strslice(p.lineno(1), p[1], p[2][0], p[2][1])


def p_string_expr_lp(p):
    """ string : LP expr RP substr
    """
    if p[1].type_ != TYPE.string:
        syntax_error(p.lexer.lineno,
                     "Expected a TYPE.string type expression. "
                     "Got '%s' one instead" % TYPE.to_string(p[1].type_))
        p[0] = None
    else:
        p[0] = make_strslice(p.lexer.lineno, p[1], p[2][0], p[2][1])


def p_subind_str(p):
    """ substr : LP expr TO expr RP
    """
    p[0] = (make_typecast(TYPE.uinteger, p[2], p.lineno(1)),
            make_typecast(TYPE.uinteger, p[4], p.lineno(3)))


def p_subind_strTO(p):
    """ substr : LP TO expr RP
    """
    p[0] = (make_typecast(TYPE.uinteger, make_number(0, lineno=p.lineno(2)),
                          p.lineno(1)),
            make_typecast(TYPE.uinteger, p[3], p.lineno(2)))


def p_subind_TOstr(p):
    """ substr : LP expr TO RP
    """
    p[0] = (make_typecast(TYPE.uinteger, p[2], p.lineno(1)),
            make_typecast(TYPE.uinteger,
                          make_number(gl.MAX_STRSLICE_IDX, lineno=p.lineno(4)),
                          lineno=p.lineno(4)),
            p.lineno(3))


def p_subind_TO(p):
    """ substr : LP TO RP
    """
    p[0] = (make_typecast(TYPE.uinteger,
                          make_number(0, lineno=p.lineno(2)),
                          p.lineno(1)),
            make_typecast(TYPE.uinteger,
                          make_number(gl.MAX_STRSLICE_IDX, lineno=p.lineno(3)),
                          p.lineno(2)))


def p_exprstr_file(p):
    """ expr : __FILE__
    """
    p[0] = symbols.STRING(gl.FILENAME, p.lineno(1))


def p_id_expr(p):
    """ expr : ID
    """
    entry = SYMBOL_TABLE.access_id(p[1], p.lineno(1), default_class=CLASS.var)
    if entry is None:
        p[0] = None
        return

    entry.accessed = True
    if entry.type_ == TYPE.auto:
        entry.type_ = _TYPE(gl.DEFAULT_TYPE)
        api.errmsg.warning_implicit_type(p.lineno(1), p[1], entry.type_)

    p[0] = entry

    """
    if entry.class_ == CLASS.var:
        if entry.type_ == TYPE.auto:
            entry.type_ = SYMBOL_TABLE.basic_types[gl.DEFAULT_TYPE]
            #api.errmsg.warning_implicit_type(p.lineno(1), p[1], entry.type_)
    """
    if entry.class_ == CLASS.array:
        if not LET_ASSIGNMENT:
            syntax_error(p.lineno(1), "Variable '%s' is an array and cannot be used in this context" % p[1])
            p[0] = None
    elif entry.kind == KIND.function:  # Function call with 0 args
        p[0] = make_call(p[1], p.lineno(1), make_arg_list(None))
    elif entry.kind == KIND.sub:  # Forbidden for subs
        syntax_error(p.lineno(1), "'%s' is SUB not a FUNCTION" % p[1])
        p[0] = None


def p_addr_of_id(p):
    """ expr : ADDRESSOF ID
    """
    entry = SYMBOL_TABLE.access_id(p[2], p.lineno(2))
    if entry is None:
        p[0] = None
        return

    entry.accessed = True
    result = make_unary(p.lineno(1), 'ADDRESS', entry, type_=_TYPE(gl.PTR_TYPE))

    if is_dynamic(entry):
        p[0] = result
    else:
        p[0] = make_constexpr(p.lineno(1), result)


def p_expr_funccall(p):
    """ expr : func_call
    """
    p[0] = p[1]


def p_idcall_expr(p):
    """ func_call : ID arg_list
    """  # This can be a function call, an array call or a string index
    p[0] = make_call(p[1], p.lineno(1), p[2])
    if p[0] is None:
        return

    if p[0].token in ('STRSLICE', 'VAR'):
        entry = SYMBOL_TABLE.access_call(p[1], p.lineno(1))
        entry.accessed = True
        return

    # TODO: Check that arrays really needs kind=function to be set
    # Both array accesses and functions are tagged as functions
    # functions also has the class_ attribute set to 'function'
    p[0].entry.set_kind(KIND.function, p.lineno(1))
    p[0].entry.accessed = True


def p_addr_of_func_call(p):
    """ expr : ADDRESSOF ID arg_list
    """
    p[0] = None

    if p[3] is None:
        return

    result = make_array_access(p[2], p.lineno(2), p[3])
    if result is None:
        return

    result.entry.accessed = True
    p[0] = make_unary(p.lineno(1), 'ADDRESS', result, type_=_TYPE(gl.PTR_TYPE))


def p_arg_list(p):
    """ arg_list : LP RP
    """
    p[0] = make_arg_list(None)


def p_arg_list_arg(p):
    """ arg_list : LP arguments RP
    """
    p[0] = p[2]


def p_arguments(p):
    """ arguments : arguments COMMA expr
    """
    p[0] = make_arg_list(p[1], make_argument(p[3], p.lineno(2)))


def p_argument(p):
    """ arguments : expr
    """
    p[0] = make_arg_list(make_argument(p[1], p.lineno(1)))


def p_funcdecl(p):
    """ function_declaration : function_header function_body
    """
    if p[1] is None:
        p[0] = None
        return

    p[0] = p[1]
    p[0].local_symbol_table = SYMBOL_TABLE.table[SYMBOL_TABLE.current_scope]
    p[0].locals_size = SYMBOL_TABLE.leave_scope()
    FUNCTION_LEVEL.pop()
    p[0].entry.body = p[2]

    entry = p[0].entry
    if entry.forwarded:
        entry.forwarded = False


def p_funcdeclforward(p):
    """ function_declaration : DECLARE function_header
    """
    if p[2] is None:
        if FUNCTION_LEVEL:
            FUNCTION_LEVEL.pop()
        return

    if p[2].entry.forwarded:
        syntax_error(p.lineno(1), "duplicated declaration for function '%s'" % p[2].name)

    p[2].entry.forwarded = True
    SYMBOL_TABLE.leave_scope()
    FUNCTION_LEVEL.pop()


def p_function_header(p):
    """ function_header : function_def param_decl typedef NEWLINE
                        | function_def param_decl typedef CO
    """
    if p[1] is None or p[2] is None:
        p[0] = None
        return

    forwarded = p[1].entry.forwarded

    p[0] = p[1]
    p[0].appendChild(p[2])
    p[0].params_size = p[2].size

    previoustype_ = p[0].type_
    if not p[3].implicit or p[0].entry.type_ is None:
        p[0].type_ = p[3]

    if forwarded and previoustype_ != p[0].type_:
        api.errmsg.syntax_error_func_type_mismatch(p.lineno(4), p[0].entry)
        p[0] = None
        return

    if forwarded:  # Was predeclared, check parameters match
        p1 = p[0].entry.params  # Param list previously declared
        p2 = p[2].children

        if len(p1) != len(p2):
            api.errmsg.syntax_error_parameter_mismatch(p.lineno(4), p[0].entry)
            p[0] = None
            return

        for a, b in zip(p1, p2):
            if a.name != b.name:
                warning(p.lineno(4), "Parameter '%s' in function '%s' has been renamed to '%s'" %
                        (a.name, p[0].name, b.name))

            if a.type_ != b.type_ or a.byref != b.byref:
                api.errmsg.syntax_error_parameter_mismatch(p.lineno(4), p[0].entry)
                p[0] = None
                return

    p[0].entry.params = p[2]

    if FUNCTION_LEVEL[-1].kind == KIND.sub and not p[3].implicit:
        syntax_error(p.lineno(4), 'SUBs cannot have a return type definition')
        p[0] = None
        return

    if p[0].entry.convention == CONVENTION.fastcall and len(p[2]) > 1:
        kind = 'SUB' if FUNCTION_LEVEL[-1].kind == KIND.sub else 'FUNCTION'
        warning(p.lineno(4), "%s '%s' declared as FASTCALL with %i parameters" % (kind, p[0].entry.name,
                                                                                  len(p[2])))


def p_function_error(p):
    """ function_declaration : function_header program END error NEWLINE
    """
    p[0] = None
    syntax_error(p.lineno(3), "Unexpected token 'END'. Expected 'END FUNCTION' or 'END SUB' instead.")


def p_function_def(p):
    """ function_def : FUNCTION convention ID
                     | SUB convention ID
    """
    p[0] = make_func_declaration(p[3], p.lineno(3))
    SYMBOL_TABLE.enter_scope(p[3])
    FUNCTION_LEVEL.append(SYMBOL_TABLE.get_entry(p[3]))
    FUNCTION_LEVEL[-1].convention = p[2]

    if p[0] is not None:
        kind = KIND.sub if p[1] == 'SUB' else KIND.function  # Must be 'function' or 'sub'
        FUNCTION_LEVEL[-1].set_kind(kind, p.lineno(1))


def p_convention(p):
    """ convention :
                   | STDCALL
    """
    p[0] = CONVENTION.stdcall


def p_convention2(p):
    """ convention : FASTCALL
    """
    p[0] = CONVENTION.fastcall


def p_param_decl_none(p):
    """ param_decl :
                   | LP RP
    """
    p[0] = make_param_list(None)


def p_param_decl(p):
    """ param_decl : LP param_decl_list RP
    """
    p[0] = p[2]


def p_param_decl_errpr(p):
    """ param_decl : LP error RP
    """
    p[0] = None


def p_param_decl_list(p):
    """ param_decl_list : param_definition
    """
    p[0] = make_param_list(p[1])


def p_param_decl_list2(p):
    """ param_decl_list : param_decl_list COMMA param_definition
    """
    p[0] = make_param_list(p[1], p[3])


def p_param_byref_definition(p):
    """ param_definition : BYREF param_def
    """
    p[0] = p[2]

    if p[0] is not None:
        p[0].byref = True


def p_param_byval_definition(p):
    """ param_definition : BYVAL param_def
    """
    p[0] = p[2]

    if p[0] is not None:
        p[0].byref = False


def p_param_definition(p):
    """ param_definition : param_def
    """
    p[0] = p[1]
    if p[0] is not None:
        p[0].byref = OPTIONS.byref.value


def p_param_def_type(p):
    """ param_def : ID typedef
    """
    p[0] = make_param_decl(p[1], p.lineno(1), p[2])


def p_function_body(p):
    """ function_body : program END FUNCTION
                      | program END SUB
                      | END FUNCTION
                      | END SUB
    """
    if not FUNCTION_LEVEL:
        syntax_error(p.lineno(3), "Unexpected token 'END %s'. No Function or Sub has been defined." % p[2])
        p[0] = None
        return

    a = FUNCTION_LEVEL[-1].kind
    if a not in (KIND.sub, KIND.function):  # This function/sub was not correctly declared, so exit now
        p[0] = None
        return

    i = 2 if p[1] == 'END' else 3
    b = p[i].lower()

    if a != b:
        syntax_error(p.lineno(i), "Unexpected token 'END %s'. Should be 'END %s'" % (b.upper(), a.upper()))
        p[0] = None
    else:
        p[0] = None if p[1] == 'END' else p[1]


def p_type_def_empty(p):
    """ typedef :
    """  # Epsilon. Defaults to float
    p[0] = make_type(_TYPE(gl.DEFAULT_TYPE).name, p.lexer.lineno, implicit=True)


def p_type_def(p):
    """ typedef : AS type
    """  # Epsilon. Defaults to float
    p[0] = make_type(p[2], p.lineno(2), implicit=False)


def p_type(p):
    """ type : BYTE
             | UBYTE
             | INTEGER
             | UINTEGER
             | LONG
             | ULONG
             | FIXED
             | FLOAT
             | STRING
    """
    p[0] = p[1].lower()


# Some preprocessor directives
def p_preprocessor_line(p):
    """ preproc_line : preproc_line_line NEWLINE
    """


def p_preprocessor_line_line(p):
    """ preproc_line_line : _LINE INTEGER
    """
    p.lexer.lineno = int(p[2]) + p.lexer.lineno - p.lineno(2)


def p_preprocessor_line_line_file(p):
    """ preproc_line_line : _LINE INTEGER STRING
    """
    p.lexer.lineno = int(p[2]) + p.lexer.lineno - p.lineno(3) - 1
    gl.FILENAME = p[3]


def p_preproc_line_init(p):
    """ preproc_line : _INIT ID
    """
    INITS.add(p[2])


def p_preproc_line_require(p):
    """ preproc_line : _REQUIRE STRING
    """
    REQUIRES.add(p[2])


def p_preproc_line_option(p):
    """ preproc_line : _PRAGMA ID EQ ID
                     | _PRAGMA ID EQ STRING
                     | _PRAGMA ID EQ INTEGER
    """
    OPTIONS.option(p[2]).value = p[4]


def p_preproc_line_push(p):
    """ preproc_line : _PRAGMA _PUSH LP ID RP
    """
    OPTIONS.option(p[4]).push()


def p_preproc_line_pop(p):
    """ preproc_line : _PRAGMA _POP LP ID RP
    """
    OPTIONS.option(p[4]).pop()


# ----------------------------------------
# INTERNAL BASIC Functions
# These will be implemented in the TRADuctor
# module as a CALL to an ASM function
# ----------------------------------------

def p_expr_usr(p):
    """ expr : USR expr %prec UMINUS
    """
    if p[2].type_ == TYPE.string:
        p[0] = make_builtin(p.lineno(1), 'USR_STR', p[2], type_=TYPE.uinteger)
    else:
        p[0] = make_builtin(p.lineno(1), 'USR',
                            make_typecast(TYPE.uinteger, p[2], p.lineno(1)),
                            type_=TYPE.uinteger)


def p_expr_rnd(p):
    """ expr : RND
             | RND LP RP
    """
    p[0] = make_builtin(p.lineno(1), 'RND', None, type_=TYPE.float_)


def p_expr_peek(p):
    """ expr : PEEK expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'PEEK',
                        make_typecast(TYPE.uinteger, p[2], p.lineno(1)),
                        type_=TYPE.ubyte)


def p_expr_peektype_(p):
    """ expr : PEEK LP numbertype COMMA expr RP
    """
    p[0] = make_builtin(p.lineno(1), 'PEEK',
                        make_typecast(TYPE.uinteger, p[5], p.lineno(4)),
                        type_=p[3])


def p_expr_in(p):
    """ expr : IN expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'IN',
                        make_typecast(TYPE.uinteger, p[2], p.lineno(1)),
                        type_=TYPE.ubyte)


def p_expr_lbound(p):
    """ expr : LBOUND LP ID RP
             | UBOUND LP ID RP
    """
    entry = SYMBOL_TABLE.access_array(p[3], p.lineno(3))
    if entry is None:
        p[0] = None
        return

    entry.accessed = True

    if p[1] == 'LBOUND':
        p[0] = make_number(entry.bounds[OPTIONS.array_base.value].lower,
                           p.lineno(3), TYPE.uinteger)
    else:
        p[0] = make_number(entry.bounds[OPTIONS.array_base.value].upper,
                           p.lineno(3), TYPE.uinteger)


def p_expr_lbound_expr(p):
    """ expr : LBOUND LP ID COMMA expr RP
             | UBOUND LP ID COMMA expr RP
    """
    entry = SYMBOL_TABLE.access_array(p[3], p.lineno(3))
    if entry is None:
        p[0] = None
        return

    entry.accessed = True
    num = make_typecast(TYPE.uinteger, p[5], p.lineno(6))

    if is_number(num):
        if num.value == 0:  # 0 => Number of dims
            p[0] = make_number(len(entry.bounds), p.lineno(3), TYPE.uinteger)
            return

        val = num.value - 1
        if val < 0 or val >= len(entry.bounds):
            syntax_error(p.lineno(6), "Dimension out of range")
            p[0] = None
            return

        if p[1] == 'LBOUND':
            p[0] = make_number(entry.bounds[val].lower, p.lineno(3), TYPE.uinteger)
        else:
            p[0] = make_number(entry.bounds[val].upper, p.lineno(3), TYPE.uinteger)
        return

    if p[1] == 'LBOUND':
        entry.lbound_used = True
    else:
        entry.ubound_used = True

    p[0] = make_builtin(p.lineno(1), p[1], [entry, num], type_=TYPE.uinteger)


def p_len(p):
    """ expr : LEN expr %prec UMINUS
    """
    arg = p[2]
    if arg is None:
        p[0] = None
    elif isinstance(arg, symbols.VAR) and arg.class_ == CLASS.array:
        p[0] = make_number(len(arg.bounds), lineno=p.lineno(1))  # Do constant folding
    elif arg.type_ != TYPE.string:
        api.errmsg.syntax_error_expected_string(p.lineno(1), TYPE.to_string(arg.type_))
        p[0] = None
    elif is_string(arg):  # Constant string?
        p[0] = make_number(len(arg.value), lineno=p.lineno(1))  # Do constant folding
    else:
        p[0] = make_builtin(p.lineno(1), 'LEN', arg, type_=TYPE.uinteger)


def p_sizeof(p):
    """ expr : SIZEOF LP type RP
             | SIZEOF LP ID RP
    """
    if TYPE.to_type(p[3].lower()) is not None:
        p[0] = make_number(TYPE.size(TYPE.to_type(p[3].lower())),
                           lineno=p.lineno(3))
    else:
        entry = SYMBOL_TABLE.get_id_or_make_var(p[3], p.lineno(1))
        p[0] = make_number(TYPE.size(entry.type_), lineno=p.lineno(3))


def p_str(p):
    """ string : STR LP expr RP %prec UMINUS
    """
    if is_number(p[3]):  # A constant is converted to string directly
        p[0] = symbols.STRING(str(p[3].value), p.lineno(1))
    else:
        p[0] = make_builtin(p.lineno(1), 'STR',
                            make_typecast(TYPE.float_, p[3], p.lineno(2)),
                            type_=TYPE.string)


def p_inkey(p):
    """ string : INKEY
    """
    p[0] = make_builtin(p.lineno(1), 'INKEY', None, type_=TYPE.string)


def p_chr_one(p):
    """ string : CHR expr %prec UMINUS
    """
    arg_list = make_arg_list(make_argument(p[2], p.lineno(1)))
    arg_list[0].value = make_typecast(TYPE.ubyte, arg_list[0].value, p.lineno(1))
    p[0] = make_builtin(p.lineno(1), 'CHR', arg_list, type_=TYPE.string)


def p_chr(p):
    """ string : CHR arg_list
    """
    if len(p[2]) < 1:
        syntax_error(p.lineno(1), "CHR$ function need at less 1 parameter")
        p[0] = None
        return

    for i in range(len(p[2])):  # Convert every argument to 8bit unsigned
        p[2][i].value = make_typecast(TYPE.ubyte, p[2][i].value, p.lineno(1))

    p[0] = make_builtin(p.lineno(1), 'CHR', p[2], type_=TYPE.string)


def p_val(p):
    """ expr : VAL expr %prec UMINUS
    """

    def val(s):
        try:
            x = float(s)
        except:
            x = 0
            warning(p.lineno(1), "Invalid string numeric constant '%s' evaluated as 0" % s)
        return x

    if p[2].type_ != TYPE.string:
        api.errmsg.syntax_error_expected_string(p.lineno(1), TYPE.to_string(p[2].type_))
        p[0] = None
    else:
        p[0] = make_builtin(p.lineno(1), 'VAL', p[2], lambda x: val(x), type_=TYPE.float_)


def p_code(p):
    """ expr : CODE expr %prec UMINUS
    """

    def asc(x):
        if len(x):
            return ord(x[0])

        return 0

    if p[2] is None:
        p[0] = None
        return

    if p[2].type_ != TYPE.string:
        api.errmsg.syntax_error_expected_string(p.lineno(1), TYPE.to_string(p[2].type_))
        p[0] = None
    else:
        p[0] = make_builtin(p.lineno(1), 'CODE', p[2], lambda x: asc(x), type_=TYPE.ubyte)


def p_sgn(p):
    """ expr : SGN expr %prec UMINUS
    """
    sgn = lambda x: x < 0 and -1 or x > 0 and 1 or 0

    if p[2].type_ == TYPE.string:
        syntax_error(p.lineno(1), "Expected a numeric expression, got TYPE.string instead")
        p[0] = None
    else:
        if is_unsigned(p[2]) and not is_number(p[2]):
            warning(p.lineno(1), "Sign of unsigned value is always 0 or 1")

        p[0] = make_builtin(p.lineno(1), 'SGN', p[2], lambda x: sgn(x), type_=TYPE.byte_)


# ----------------------------------------
# Trigonometrics
# ----------------------------------------
def p_expr_sin(p):
    """ expr : SIN expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'SIN',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.sin(x))


def p_expr_cos(p):
    """ expr : COS expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'COS',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.cos(x))


def p_expr_tan(p):
    """ expr : TAN expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'TAN',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.tan(x))


def p_expr_asin(p):
    """ expr : ASN expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'ASN',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.asin(x))


def p_expr_acos(p):
    """ expr : ACS expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'ACS',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.acos(x))


def p_expr_atan(p):
    """ expr : ATN expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'ATN',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.atan(x))


# ----------------------------------------
# Square root, Exponent and logarithms
# ----------------------------------------
def p_expr_exp(p):
    """ expr : EXP expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'EXP',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.exp(x))


def p_expr_logn(p):
    """ expr : LN expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'LN',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.log(x))


def p_expr_sqrt(p):
    """ expr : SQR expr %prec UMINUS
    """
    p[0] = make_builtin(p.lineno(1), 'SQR',
                        make_typecast(TYPE.float_, p[2], p.lineno(1)),
                        lambda x: math.sqrt(x))


# ----------------------------------------
# Other important functions
# ----------------------------------------
def p_expr_int(p):
    """ expr : INT expr %prec UMINUS
    """
    p[0] = make_typecast(TYPE.long_, p[2], p.lineno(1))


def p_abs(p):
    """ expr : ABS expr %prec UMINUS
    """
    if is_unsigned(p[2]):
        p[0] = p[2]
        warning(p.lineno(1), "Redundant operation ABS for unsigned value")
        return

    p[0] = make_builtin(p.lineno(1), 'ABS', p[2], lambda x: x if x >= 0 else -x)


# ----------------------------------------
# The yyerror function
# ----------------------------------------
def p_error(p):
    gl.has_errors += 1

    if p is not None:
        if p.type != 'NEWLINE':
            msg = "%s:%i: Syntax Error. Unexpected token '%s' <%s>" % \
                  (gl.FILENAME, p.lexer.lineno, p.value, p.type)
        else:
            msg = "%s:%i: Unexpected end of file" % \
                  (gl.FILENAME, p.lexer.lineno)
    else:
        msg = "%s:%i: Unexpected end of file" % \
              (gl.FILENAME, zxblex.lexer.lineno)

    OPTIONS.stderr.value.write("%s\n" % msg)


# ----------------------------------------
# Initialization
# ----------------------------------------
parser = yacc.yacc(method='LALR', tabmodule='parsetab.zxbtab', debug=OPTIONS.Debug.value > 2)
ast = None
data_ast = None  # Global Variables AST
optemps = OpcodesTemps()
