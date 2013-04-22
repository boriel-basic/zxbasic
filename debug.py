#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et:

# Simple debugging module

import sys

from common import OPTIONS

# --------------------- END OF GLOBAL FLAGS ---------------------

import inspect

def __DEBUG__(msg, level = 1):
    if level > OPTIONS.Debug.value:
        return

    line = inspect.getouterframes(inspect.currentframe())[1][2]
    OPTIONS.stderr.value.write('debug: %i: %s\n' % (line, msg))


def __LINE__():
    ''' Returns current file interpreter line
    '''
    return inspect.getouterframes(inspect.currentframe())[1][2]
    

def __FILE__():
    ''' Returns current file interpreter line
    '''
    return inspect.currentframe().f_code.co_filename

