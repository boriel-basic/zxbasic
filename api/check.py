#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import config
import global_
from constants import CLASS
from constants import TYPE
from constants import SCOPE
from errmsg import syntax_error


__all__ = ['check_type',
           'check_is_declared',
           'check_call_arguments',
           'check_pending_calls',
           'check_pending_labels',
           'is_number',
           'is_const',
           'is_string'
           ]

# ----------------------------------------------------------------------
# Several check functions.
# These functions trigger syntax errors if checking goal fails.
# ----------------------------------------------------------------------


def check_type(lineno, type_list, arg):
    ''' Check arg's type is one in type_list, otherwise,
    raises an error.
    '''
    if not isinstance(type_list, list):
        type_list = [type_list]

    if arg.type_ in type_list:
        return True

    if len(type_list) == 1:
        syntax_error(lineno, "Wrong expression type '%s'. Expected '%s'" %
                     (arg.type_, type_list[0]))
    else:
        syntax_error(lineno, "Wrong expression type '%s'. Expected one of '%s'"
                     % (arg.type_, tuple(type_list)))

    return False


def check_is_declared(lineno, id_, classname='variable'):
    ''' Check if the current ID is already declared.
    If not, triggers a "undeclared identifier" error,
    if the --strict command line flag is enabled (or #pragma
    option strict is in use).

    If not in strict mode, passes it silently.
    '''
    if not config.OPTIONS.explicit.value:
        return True

    entry = global_.SYMBOL_TABLE.check_is_declared(id_, lineno, classname)
    return entry is not None  # True if declared


def check_call_arguments(lineno, id_, args):
    ''' Check arguments against function signature.

        Checks every argument in a function call against a function.
        Returns True on success.
    '''
    entry = global_.SYMBOL_TABLE.check_declared(id_, lineno, 'function')
    if entry is None:
        return False

    if not global_.SYMBOL_TABLE.check_class(id_, CLASS.function, lineno):
        return False

    if not hasattr(entry, 'params'):
        return False

    if len(args) != len(entry.params):
        c = 's' if len(entry.params) != 1 else ''
        syntax_error(lineno, "Function '%s' takes %i parameter%s, not %i" %
                     (id_, len(entry.params), c, len(args)))
        return False

    for arg, param in zip(args, entry.params):
        if not arg.typecast(param.type_):
            return False

        if param.byref:
            from symbols.var import SymbolVAR
            if not isinstance(arg, SymbolVAR):
                syntax_error(lineno, "Expected a variable name, not an "
                                     "expression (parameter By Reference)")
                return False

            if arg.class_ not in (CLASS.var, CLASS.array):
                syntax_error(lineno, "Expected a variable or array name "
                                     "(parameter By Reference)")
                return False

            arg.byref = True

    return True


def check_pending_calls():
    ''' Calls the above function for each pending call of the current scope
    level
    '''
    result = True

    # Check for functions defined after calls (parametres, etc)
    for id_, params, lineno in global_.FUNCTION_CALLS:
        result = result and check_call_arguments(lineno, id_, params)

    return result


def check_pending_labels(ast):
    ''' Iteratively traverses the ast looking for ID with no class set,
    marks them as labels, and check they've been declared.

    This way we avoid stack overflow for high line-numbered listings.
    '''
    result = True
    pending = [ast]

    while pending:
        ast = pending.pop()

        if ast is None:
            continue

        for x in ast.children:
            pending += [x]

        if ast.token != 'ID' or (ast.token == 'ID' and ast.class_ is not None):
            continue

        tmp = global_.SYMBOL_TABLE.get_id_entry(ast.name)
        if tmp is None or tmp.class_ is None:
            syntax_error(ast.lineno, 'Undeclared identifier "%s"'
                         % ast.name)
        else:
            ast.symbol = tmp

        result = result and tmp is not None

    return result


# ----------------------------------------------------------------------
# Function for checking some arguments
# ----------------------------------------------------------------------
def is_SYMBOL(token, *symbols):
    ''' Returns True if ALL of the given argument are AST nodes
    of the given token (e.g. 'BINARY')
    '''
    for sym in symbols:
        if sym.token != token:
            return False

    return True


def is_string(*p):
    return is_SYMBOL('STRING', *p)


def is_const(*p):
    return is_SYMBOL('CONST', *p)


def is_number(*p):
    ''' Returns True if ALL of the arguments are AST nodes
    containing NUMBER constants
    '''
    try:
        for i in p:
            if i.token != 'NUMBER' and (i.token != 'ID' or
                                        i.class_ != CLASS.const):
                return False

        return True
    except:
        pass

    return False


def is_id(*p):
    ''' Returns True if ALL of the arguments are AST nodes
    containing ID
    '''
    return is_SYMBOL('ID', *p)


def is_integer(*p):
    try:
        for i in p:
            if i.is_basic and i.type_.type_ not in TYPE.integral:
                return False

        return True
    except:
        pass

    return False


def is_unsigned(*p):
    ''' Returns false unless all types in p are unsigned
    '''
    try:
        for i in p:
            if i.is_basic and i.type_.type_ not in TYPE.unsigned:
                return False

        return True
    except:
        pass

    return False


def is_signed(*p):
    ''' Returns false unless all types in p are signed
    '''
    try:
        for i in p:
            if i.is_basic and i.type_.type_ not in TYPE.signed:
                return False

        return True
    except:
        pass

    return False


def is_numeric(*p):
    try:
        for i in p:
            if i.is_basic and i.type_.type_ not in TYPE.numbers:
                return False

        return True
    except:
        pass

    return False


def is_type(type_, *p):
    ''' True if all args have the same type
    '''
    try:
        for i in p:
            if i.type_ != type_:
                return False

        return True
    except:
        pass

    return False


def is_dynamic(*p):
    ''' True if all args are dynamic (e.g. Strings, dynamic arrays, etc)
    '''
    try:
        for i in p:
            if i.scope == SCOPE.global_ and i.is_basic and \
                            i.type_.type_ != TYPE.string:
                return False

        return True
    except:
        pass

    return False


def common_type(a, b):
    ''' Returns a type which is common for both a and b types.
    Returns None if no common types allowed.
    '''
    if a is None or b is None:
        return None

    if a.type_ == b.type_:    # Both types are the same?
        return a.type_        # Returns it

    if a.type_ is None and b.type_ is None:
        return global_.DEFAULT_TYPE

    if a.type_ is None:
        return b.type_

    if b.type_ is None:
        return a.type_

    assert a.type_.is_basic
    assert b.type_.is_basic

    types = (a.type_.type_, b.type_.type_)

    if TYPE.float_ in types:
        return TYPE.float_

    if TYPE.fixed in types:
        return TYPE.fixed

    if TYPE.string in types:
        return TYPE.string

    result = a.type_ if TYPE.size(a.type_) > TYPE.size(b.type_) else b.type_

    if not is_unsigned(a, b):
        result = TYPE.to_signed(result)

    return result
