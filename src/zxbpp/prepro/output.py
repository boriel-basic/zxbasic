# vim:ts=4:et:sw=4:

"""Common output functions for the preprocessor.
Need the global OPTION object
"""

import src.api.errmsg
from src.api.errmsg import register_warning

CURRENT_FILE: list[str] = []  # The current file being processed


# Wraps error() and warning(), for future local features
def error(lineno: int, msg: str, fname: str | None = None):
    src.api.errmsg.error(lineno, msg, fname=fname)


def warning(lineno: int, msg: str, fname: str | None = None):
    src.api.errmsg.warning(lineno, msg, fname=fname)


# Local warnings
@register_warning("500")
def warning_overwrite_builtin_macro(macro_name: str, lineno: int, fname: str | None = None):
    warning(lineno, f'builtin macro "{macro_name}" redefined', fname=fname)


@register_warning("510")
def warning_redefined_macro(macro_name: str, lineno: int, fname: str | None = None):
    warning(lineno, f'"{macro_name}" redefined (previous definition at {fname}:{lineno})', fname=fname)


@register_warning("520")
def warning_missing_whitespace_after_macro(lineno: int, fname: str | None = None):
    warning(lineno, "missing whitespace after macro name", fname=fname)
