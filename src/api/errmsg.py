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
from typing import Optional

from . import global_
from .config import OPTIONS

# Exports only these functions. Others
__all__ = ['error', 'warning']


def msg_output(msg):
    if msg in global_.error_msg_cache:
        return

    OPTIONS.stderr.write("%s\n" % msg)
    global_.error_msg_cache.add(msg)


def info(msg):
    if OPTIONS.Debug < 1:
        return
    OPTIONS.stderr.write("info: %s\n" % msg)


def error(lineno, msg, fname: Optional[str] = None):
    """ Generic syntax error routine
    """
    if fname is None:
        fname = global_.FILENAME

    if global_.has_errors > OPTIONS.max_syntax_errors:
        msg = 'Too many errors. Giving up!'

    msg = "%s:%i: error: %s" % (fname, lineno, msg)
    msg_output(msg)

    if global_.has_errors > OPTIONS.max_syntax_errors:
        sys.exit(1)

    global_.has_errors += 1


def warning(lineno, msg, fname: Optional[str] = None):
    """ Generic warning error routine
    """
    if fname is None:
        fname = global_.FILENAME

    msg = "%s:%i: warning: %s" % (fname, lineno, msg)
    msg_output(msg)
    global_.has_warnings += 1


def warning_implicit_type(lineno, id_, type_=None):
    """ Warning: Using default implicit type 'x'
    """
    if OPTIONS.strict:
        syntax_error_undeclared_type(lineno, id_)
        return

    if type_ is None:
        type_ = global_.DEFAULT_TYPE

    warning(lineno, "Using default implicit type '%s' for '%s'" % (type_, id_))


def warning_condition_is_always(lineno, cond=False):
    """ Warning: Condition is always false/true
    """
    warning(lineno, "Condition is always %s" % cond)


def warning_conversion_lose_digits(lineno):
    """ Warning: Conversion may lose significant digits
    """
    warning(lineno, 'Conversion may lose significant digits')


def warning_empty_loop(lineno):
    """ Warning: Empty loop
    """
    warning(lineno, 'Empty loop')


def warning_empty_if(lineno):
    """ Warning: Useless empty IF ignored
    """
    warning(lineno, 'Useless empty IF ignored')


# Emmits an optimization warning
def warning_not_used(lineno, id_, kind='Variable'):
    if OPTIONS.optimization > 0:
        warning(lineno, "%s '%s' is never used" % (kind, id_))


# ----------------------------------------
# Syntax error: Expected string instead of
#               numeric expression.
# ----------------------------------------
def syntax_error_expected_string(lineno, _type):
    error(lineno, "Expected a 'string' type expression, got '%s' instead" % _type)


# ----------------------------------------
# Syntax error: FOR variable should be X
#               instead of Y
# ----------------------------------------
def syntax_error_wrong_for_var(lineno, x, y):
    error(lineno, "FOR variable should be '%s' instead of '%s'" %
          (x, y))


# ----------------------------------------
# Syntax error: Initializer expression is
#               not constant
# ----------------------------------------
def syntax_error_not_constant(lineno):
    error(lineno, "Initializer expression is not constant.")


# ----------------------------------------
# Syntax error: Id is neither an array nor
#               a function
# ----------------------------------------
def syntax_error_not_array_nor_func(lineno, varname):
    error(lineno, "'%s' is neither an array nor a function." % varname)


# ----------------------------------------
# Syntax error: Id is neither an array nor
#               a function
# ----------------------------------------
def syntax_error_not_an_array(lineno, varname):
    error(lineno, "'%s' is not an array (or has not been declared yet)" % varname)


# ----------------------------------------
# Syntax error: function redefinition type
#               mismatch
# ----------------------------------------
def syntax_error_func_type_mismatch(lineno, entry):
    error(lineno, "Function '%s' (previously declared at %i) type mismatch" % (entry.name, entry.lineno))


# ----------------------------------------
# Syntax error: function redefinition parm.
#               mismatch
# ----------------------------------------
def syntax_error_parameter_mismatch(lineno, entry):
    error(lineno, "Function '%s' (previously declared at %i) parameter mismatch" % (entry.name, entry.lineno))


# ----------------------------------------
# Syntax error: can't convert value to the
#               given type.
# ----------------------------------------
def syntax_error_cant_convert_to_type(lineno, expr_str, type_):
    error(lineno, "Cant convert '%s' to type %s" % (expr_str, type_))


# ----------------------------------------
# Syntax error: is a SUB not a FUNCTION
# ----------------------------------------
def syntax_error_is_a_sub_not_a_func(lineno, name):
    error(lineno, "'%s' is SUBROUTINE not a FUNCTION" % name)


# ----------------------------------------
# Syntax error: strict mode: missing type declaration
# ----------------------------------------
def syntax_error_undeclared_type(lineno: int, id_: str):
    error(lineno, "strict mode: missing type declaration for '%s'" % id_)


# ----------------------------------------
#  Cannot assign a value to 'var'. It's not a variable
# ----------------------------------------
def syntax_error_cannot_assign_not_a_var(lineno, id_):
    error(lineno, "Cannot assign a value to '%s'. It's not a variable" % id_)


# ----------------------------------------
#  Cannot assign a value to 'var'. It's not a variable
# ----------------------------------------
def syntax_error_address_must_be_constant(lineno):
    error(lineno, 'Address must be a numeric constant expression')


# ----------------------------------------
#  Cannot pass an array by value
# ----------------------------------------
def syntax_error_cannot_pass_array_by_value(lineno, id_):
    error(lineno, "Array parameter '%s' must be passed ByRef" % id_)
