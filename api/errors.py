#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------


# ------------------------- ERROR exception classes ---------------------------

__all__ = ['Error']


class Error(Exception):
    '''Base class for exceptions in this module.
    '''
    def __init__(self, msg='Unknown error'):
        self.msg = msg

    def __str__(self):
        return self.msg
