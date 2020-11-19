#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

""" Common output functions for the preprocessor.
Need the global OPTION object
"""

from typing import Optional

import src.api.errmsg


CURRENT_FILE = []  # The current file being processed


def error(lineno, str_, fname: Optional[str] = None):
    src.api.errmsg.error(lineno, str_, fname=fname)


def warning(lineno, str_, fname: Optional[str] = None):
    src.api.errmsg.warning(lineno, str_, fname=fname)
