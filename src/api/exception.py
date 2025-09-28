# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

__all__ = [
    "Error",
    "InternalError",
    "InvalidBuiltinFunctionError",
    "InvalidCONSTexpr",
    "InvalidLoopError",
    "InvalidOperatorError",
    "TempAlreadyFreedError",
]


class Error(Exception):
    """Base class for exceptions in this module."""

    def __init__(self, msg="Unknown error"):
        self.msg = msg

    def __str__(self):
        return self.msg


class InvalidOperatorError(Error):
    def __init__(self, operator):
        self.msg = 'Invalid operator "%s"' % str(operator)


class InvalidLoopError(Error):
    def __init__(self, loop):
        self.msg = 'Invalid loop type error (not found?) "%s"' % str(loop)


class InvalidCONSTexpr(Error):
    def __init__(self, symbol):
        self.msg = "Invalid CONST expression: %s|%s" % (symbol.token, symbol.t)


class InvalidBuiltinFunctionError(Error):
    def __init__(self, fname):
        self.msg = "Invalid BUILTIN function '%s'" % fname


class InternalError(Error):
    def __init__(self, msg):
        self.msg = msg


class TempAlreadyFreedError(InternalError):
    """Raised when a TEMP label has been already freed."""

    def __init__(self, label):
        super().__init__(f"Label '{label}' already freed")
        self.label = label
