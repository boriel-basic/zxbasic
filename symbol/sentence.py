#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from symbol import Symbol



class Sentence(Symbol):
    ''' Defines a BASIC SENTENCE object. e.g. 'BORDER'.
    '''
    def __init__(self, sentence, *args):
        Symbol.__init__(self, None, sentence)
        self.args = list(args) # Must be set o an array of args. 


