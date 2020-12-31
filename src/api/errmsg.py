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
from functools import wraps

from typing import Callable
from typing import Optional

from . import global_
from .config import OPTIONS


# Exports only these functions. Others
__all__ = [
    'error',
    'is_valid_warning_code',
    'warning',
    'warning_not_used'
]


WARNING_PREFIX: str = ''  # will be prepended to warning messages
ERROR_PREFIX: str = ''  # will be prepended to error messages


def msg_output(msg: str) -> None:
    if msg in global_.error_msg_cache:
        return

    OPTIONS.stderr.write("%s\n" % msg)
    global_.error_msg_cache.add(msg)


def info(msg: str) -> None:
    if OPTIONS.Debug < 1:
        return
    OPTIONS.stderr.write("info: %s\n" % msg)


def error(lineno: int, msg: str, fname: Optional[str] = None) -> None:
    """ Generic syntax error routine
    """
    if fname is None:
        fname = global_.FILENAME

    if global_.has_errors > OPTIONS.max_syntax_errors:
        msg = 'Too many errors. Giving up!'

    msg = "%s:%i: error:%s %s" % (fname, lineno, ERROR_PREFIX, msg)
    msg_output(msg)

    if global_.has_errors > OPTIONS.max_syntax_errors:
        sys.exit(1)

    global_.has_errors += 1


def warning(lineno: int, msg: str, fname: Optional[str] = None) -> None:
    """ Generic warning error routine
    """
    global_.has_warnings += 1
    if global_.has_warnings <= OPTIONS.expect_warnings:
        return

    if fname is None:
        fname = global_.FILENAME

    msg = "%s:%i: %s %s" % (fname, lineno, WARNING_PREFIX or 'warning:', msg)
    msg_output(msg)


def is_valid_warning_code(code: str) -> bool:
    return code in global_.ENABLED_WARNINGS


def assert_is_valid_warning_code(code: str):
    assert is_valid_warning_code(code), f"Invalid warning code '{code}'"


def enable_warning(code: str):
    assert_is_valid_warning_code(code)
    global_.ENABLED_WARNINGS[code] = True


def disable_warning(code: str):
    assert_is_valid_warning_code(code)
    global_.ENABLED_WARNINGS[code] = False


def register_warning(code: str) -> Callable:
    assert code not in global_.ENABLED_WARNINGS, f"Duplicated warning code '{code}'"
    global_.ENABLED_WARNINGS[code] = True

    def decorator(func: Callable) -> Callable:
        def wrapper(*args, **kwargs):
            global WARNING_PREFIX
            if global_.ENABLED_WARNINGS.get(code, True):
                if not OPTIONS.hide_warning_codes:
                    WARNING_PREFIX = f'warning: [W{code}]'
                func(*args, **kwargs)
                WARNING_PREFIX = ''

        return wraps(func)(wrapper)

    return decorator


# region [Warnings]
@register_warning('100')
def warning_implicit_type(lineno: int, id_: str, type_: str = None):
    """ Warning: Using default implicit type 'x'
    """
    if OPTIONS.strict:
        syntax_error_undeclared_type(lineno, id_)
        return

    if type_ is None:
        type_ = global_.DEFAULT_TYPE

    warning(lineno, "Using default implicit type '%s' for '%s'" % (type_, id_))


@register_warning('110')
def warning_condition_is_always(lineno: int, cond: bool = False):
    """ Warning: Condition is always false/true
    """
    warning(lineno, "Condition is always %s" % cond)


@register_warning('120')
def warning_conversion_lose_digits(lineno: int):
    """ Warning: Conversion may lose significant digits
    """
    warning(lineno, 'Conversion may lose significant digits')


@register_warning('130')
def warning_empty_loop(lineno: int):
    """ Warning: Empty loop
    """
    warning(lineno, 'Empty loop')


@register_warning('140')
def warning_empty_if(lineno: int):
    """ Warning: Useless empty IF ignored
    """
    warning(lineno, 'Useless empty IF ignored')


@register_warning('150')
def warning_not_used(lineno: int, id_: str, kind: str = 'Variable'):
    """ Emits an optimization warning
    """
    if OPTIONS.optimization > 0:
        warning(lineno, "%s '%s' is never used" % (kind, id_))


@register_warning('160')
def warning_fastcall_with_N_parameters(lineno: int, kind: str, id_: str, num_params: int):
    """ Warning: SUB/FUNCTION declared as FASTCALL with N parameters
    """
    warning(lineno, f"{kind} '{id_}' declared as FASTCALL with {num_params} parameters")


@register_warning('170')
def warning_func_is_never_called(lineno: int, func_name: str, fname: Optional[str] = None):
    warning(lineno, f"Function '{func_name}' is never called and has been ignored", fname=fname)

# endregion

# region [Syntax Errors]


# ----------------------------------------
# Syntax error: Expected string instead of
#               numeric expression.
# ----------------------------------------
def syntax_error_expected_string(lineno: int, _type: str):
    error(lineno, "Expected a 'string' type expression, got '%s' instead" % _type)


# ----------------------------------------
# Syntax error: FOR variable should be X
#               instead of Y
# ----------------------------------------
def syntax_error_wrong_for_var(lineno: int, x: str, y: str):
    error(lineno, "FOR variable should be '%s' instead of '%s'" % (x, y))


# ----------------------------------------
# Syntax error: Initializer expression is
#               not constant
# ----------------------------------------
def syntax_error_not_constant(lineno: int):
    error(lineno, "Initializer expression is not constant.")


# ----------------------------------------
# Syntax error: Id is neither an array nor
#               a function
# ----------------------------------------
def syntax_error_not_array_nor_func(lineno: int, varname: str):
    error(lineno, "'%s' is neither an array nor a function." % varname)


# ----------------------------------------
# Syntax error: Id is neither an array nor
#               a function
# ----------------------------------------
def syntax_error_not_an_array(lineno: int, varname: str):
    error(lineno, "'%s' is not an array (or has not been declared yet)" % varname)


# ----------------------------------------
# Syntax error: function redefinition type
#               mismatch
# ----------------------------------------
def syntax_error_func_type_mismatch(lineno: int, entry):
    error(lineno, "Function '%s' (previously declared at %i) type mismatch" % (entry.name, entry.lineno))


# ----------------------------------------
# Syntax error: function redefinition parm.
#               mismatch
# ----------------------------------------
def syntax_error_parameter_mismatch(lineno: int, entry):
    error(lineno, "Function '%s' (previously declared at %i) parameter mismatch" % (entry.name, entry.lineno))


# ----------------------------------------
# Syntax error: can't convert value to the
#               given type.
# ----------------------------------------
def syntax_error_cant_convert_to_type(lineno: int, expr_str: str, type_: str):
    error(lineno, "Cant convert '%s' to type %s" % (expr_str, type_))


# ----------------------------------------
# Syntax error: is a SUB not a FUNCTION
# ----------------------------------------
def syntax_error_is_a_sub_not_a_func(lineno: int, name: str):
    error(lineno, "'%s' is SUBROUTINE not a FUNCTION" % name)


# ----------------------------------------
# Syntax error: strict mode: missing type declaration
# ----------------------------------------
def syntax_error_undeclared_type(lineno: int, id_: str):
    error(lineno, "strict mode: missing type declaration for '%s'" % id_)


# ----------------------------------------
#  Cannot assign a value to 'var'. It's not a variable
# ----------------------------------------
def syntax_error_cannot_assign_not_a_var(lineno: int, id_: str):
    error(lineno, "Cannot assign a value to '%s'. It's not a variable" % id_)


# ----------------------------------------
#  Cannot assign a value to 'var'. It's not a variable
# ----------------------------------------
def syntax_error_address_must_be_constant(lineno: int):
    error(lineno, 'Address must be a numeric constant expression')


# ----------------------------------------
#  Cannot pass an array by value
# ----------------------------------------
def syntax_error_cannot_pass_array_by_value(lineno: int, id_: str):
    error(lineno, "Array parameter '%s' must be passed ByRef" % id_)

# endregion
