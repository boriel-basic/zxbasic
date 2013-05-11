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
from errmsg import syntax_error

from symbol import SymbolID

__all__ = ['check_type',
           'check_is_declared',
           'check_call_arguments',
           'check_pending_calls',
           'check_pending_labels'
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

    if arg._type in type_list:
        return True

    if len(type_list) == 1:
        syntax_error(lineno, "Wrong expression type '%s'. Expected '%s'" %
            (arg._type, type_list[0]))
    else:
        syntax_error(lineno, "Wrong expression type '%s'. Expected one of '%s'"
            % (arg._type, tuple(type_list)))

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

    entry = global_.SYMBOL_TABLE.check_declared(id_, lineno, classname)
    return entry is not None  # True if declared


def check_call_arguments(lineno, id_, args):
    ''' Check arguments against function signature.

        Checks every argument in a function call against a function.
        Returns True on success.
    '''
    entry = global_.SYMBOL_TABLE.check_declared(id_, lineno, 'function')
    if entry is None:
        return False

    if not global_.SYMBOL_TABLE.check_class(id_, 'function', lineno):
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

        if param.symbol.byref:
            if not isinstance(arg, SymbolID):
                syntax_error(lineno, 
                    "Expected a variable name, not an expression (parameter By Reference)")
                return False

            if arg.symbol.arg._class not in ('var', 'array'):
                syntax_error(lineno,
                    "Expected a variable or array name (parameter By Reference)")
                return False

            arg.symbol.byref = True

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

    This way we avoid stack overflow for high linenumbered listings.
    '''
    result = True
    pending = [ast]

    while pending != []:
        ast = pending.pop()

        if ast is None:
            continue

        for x in ast.next:
            pending += [x]

        if ast.token != 'ID' or (ast.token == 'ID' and ast.class_ is not None):
            continue

        tmp = global_.SYMBOL_TABLE.get_id_entry(ast.name)
        if tmp is None or tmp._class is None:
            syntax_error(ast.lineno, 'Undeclared identifier "%s"'
                % ast.name)
        else:
            ast.symbol = tmp

        result = result and tmp is not None

    return result
