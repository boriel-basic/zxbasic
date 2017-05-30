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
from . import global_
from .config import OPTIONS

# Exports only these functions. Others
__all__ = ['syntax_error', 'warning']


def syntax_error(lineno, msg):
    """ Generic syntax error routine
    """
    if global_.has_errors > OPTIONS.max_syntax_errors.value:
        msg = 'Too many errors. Giving up!'

    msg = "%s:%i: %s" % (global_.FILENAME, lineno, msg)

    OPTIONS.stderr.value.write("%s\n" % msg)

    if global_.has_errors > OPTIONS.max_syntax_errors.value:
        sys.exit(1)

    global_.has_errors += 1


def warning(lineno, msg):
    """ Generic warning error routine
    """
    msg = "%s:%i: warning: %s" % (global_.FILENAME, lineno, msg)
    OPTIONS.stderr.value.write("%s\n" % msg)

    global_.has_warnings += 1


def warning_implicit_type(lineno, id_, type_=None):
    """ Warning: Using default implicit type 'x'
    """
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


# Emmits an optimization warning
def warning_not_used(lineno, id_, kind='Variable'):
    if OPTIONS.optimization.value > 0:
        warning(lineno, "%s '%s' is never used" % (kind, id_))


# ----------------------------------------
# Syntax error: Expected string instead of
#               numeric expression.
# ----------------------------------------
def syntax_error_expected_string(lineno, _type):
    syntax_error(lineno, "Expected a 'string' type expression, got '%s' instead" % _type)


# ----------------------------------------
# Syntax error: FOR variable should be X
#               instead of Y
# ----------------------------------------
def syntax_error_wrong_for_var(lineno, x, y):
    syntax_error(lineno, "FOR variable should be '%s' instead of '%s'" %
                 (x, y))


# ----------------------------------------
# Syntax error: Initializer expression is
#               not constant
# ----------------------------------------
def syntax_error_not_constant(lineno):
    syntax_error(lineno, "Initializer expression is not constant.")


# ----------------------------------------
# Syntax error: Id is neither an array nor
#               a function
# ----------------------------------------
def syntax_error_not_array_nor_func(lineno, varname):
    syntax_error(lineno, "'%s' is neither an array nor a function." % varname)


# ----------------------------------------
# Syntax error: Id is neither an array nor
#               a function
# ----------------------------------------
def syntax_error_not_an_array(lineno, varname):
    syntax_error(lineno, "'%s' is not an array (or has not been declared yet)" % varname)


# ----------------------------------------
# Syntax error: function redefinition type
#               mismatch
# ----------------------------------------
def syntax_error_func_type_mismatch(lineno, entry):
    syntax_error(lineno, "Function '%s' (previously declared at %i) type mismatch" % (entry.name, entry.lineno))


# ----------------------------------------
# Syntax error: function redefinition parm.
#               mismatch
# ----------------------------------------
def syntax_error_parameter_mismatch(lineno, entry):
    syntax_error(lineno, "Function '%s' (previously declared at %i) parameter mismatch" % (entry.name, entry.lineno))
