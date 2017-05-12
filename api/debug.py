#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et:

# Simple debugging module

import os
import inspect

from .config import OPTIONS

__all__ = ['__DEBUG__', '__LINE__', '__FILE__']

# --------------------- END OF GLOBAL FLAGS ---------------------

def __DEBUG__(msg, level=1):
    if level > OPTIONS.Debug.value:
        return

    line = inspect.getouterframes(inspect.currentframe())[1][2]
    fname = os.path.basename(inspect.getouterframes(inspect.currentframe())[1][1])
    OPTIONS.stderr.value.write('debug: %s:%i %s\n' % (fname, line, msg))


def __LINE__():
    ''' Returns current file interpreter line
    '''
    return inspect.getouterframes(inspect.currentframe())[1][2]


def __FILE__():
    ''' Returns current file interpreter line
    '''
    return inspect.currentframe().f_code.co_filename
