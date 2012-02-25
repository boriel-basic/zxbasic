#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

from error import Error

class InvalidIC(Error):
    ''' Invalid Intermediate Code instruction
    '''
    def __init__(self, ic, msg = None):
        if msg is None:
            msg = 'Invalid intermediate code instruction: "%s"' % ic

        self.msg = msg
        self.ic = ic


