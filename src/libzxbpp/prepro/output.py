#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

""" Common output functions for the preprocessor.
Need the global OPTION object
"""

from typing import List
from typing import Optional

import src.api.errmsg


CURRENT_FILE: List[str] = []  # The current file being processed


def error(lineno: int, msg: str, fname: Optional[str] = None):
    src.api.errmsg.error(lineno, msg, fname=fname)


def warning(lineno: int, msg: str, fname: Optional[str] = None):
    src.api.errmsg.warning(lineno, msg, fname=fname)
