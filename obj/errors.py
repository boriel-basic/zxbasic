#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4

# --------------------------- ERROR exception classes ----------------------------

class Error(Exception):
    '''Base class for exceptions in this module.
    '''
    def __init__(self, msg = 'Unknown error'):
        self.msg = msg

    def __str__(self):
        return self.msg


