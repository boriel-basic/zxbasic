#!/usr/bin/env python
# -*- coding: utf-8 -*-


class PreprocError(Exception):
    ''' Denotes an exception in de preprocessor
    '''
    def __init__(self, msg, lineno):
        self.message = msg
        self.lineno = lineno

    def __str__(self):
        return self.message


