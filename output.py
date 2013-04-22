#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

''' Common output functions for the preprocessor. 
Need the global OPTION object
'''
import os
import sys

from obj import OPTIONS
CURRENT_FILE = [] # The current file being processed


def msg(lineno, smsg):
    OPTIONS.stderr.value.write('%s:%i: %s\n' % (os.path.basename(CURRENT_FILE[-1]), lineno, smsg))


def error(lineno, str):
    msg(lineno, 'Error: %s' % str)
    sys.exit(1)


def warning(lineno, str):
    msg(lineno, 'Warning: %s' % str)

