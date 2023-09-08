#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

from src.api.exception import Error

__all__ = (
    "GenericError",
    "InvalidICError",
    "NoMoreRegistersError",
    "UnsupportedError",
    "throw_invalid_quad_params",
)


class GenericError(Error):
    """Backend Generic ERROR"""

    def __init__(self, msg=None):
        if msg is None:
            msg = "Generic Backend Internal Error. Please, report this"

        self.msg = msg

    def __str__(self):
        return self.msg

    def __repr__(self):
        return "%s: %s" % (self.__class__.__name__, self.msg)


class InvalidICError(GenericError):
    """Invalid Intermediate Code instruction"""

    def __init__(self, ic, msg=None):
        if msg is None:
            msg = 'Invalid intermediate code instruction "%s"' % ic

        super(InvalidICError, self).__init__(msg)
        self.ic = ic


class NoMoreRegistersError(GenericError):
    """Raised when no more assigned register are available."""

    pass


class UnsupportedError(GenericError):
    """Raised when an unsupported feature has been used."""

    def __init__(self, feat):
        GenericError.__init__(self, "Unsupported feature '%s'" % str(feat))
        self.feature = feat


# -----------------------------------------------------------------------------
#  Functions for throwing errors
# -----------------------------------------------------------------------------
def throw_invalid_quad_params(quad, nparams):
    """Exception raised when an invalid number of params in the
    quad code has been emitted.
    """
    raise InvalidICError(str(quad), f"Invalid quad code params for '{quad}' (expected {nparams}, but got {len(quad)})")
