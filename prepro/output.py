#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

''' Common output functions for the preprocessor.
Need the global OPTION object
'''

import sys
import api.errmsg

CURRENT_FILE = []  # The current file being processed


def error(lineno, str_):
    api.errmsg.syntax_error(lineno, 'Error: %s' % str_)
    sys.exit(1)


def warning(lineno, str_):
    api.errmsg.warning(lineno, str_)
