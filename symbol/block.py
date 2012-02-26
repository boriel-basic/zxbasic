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



class Block(Symbol):
    ''' Defines a block of code.
    '''
    def __init__(self, *args):
        ''' Creates a chain of code blocks.
        '''
        Symbol.__init__(self, None, 'BLOCK')
        self.next = list(args)

    @classmethod
    def create(cls, *args):
        args = [x for x in args if x is not None]
        if not args:
            return None
    
        if args[0].token == 'BLOCK':
            args = args[0].next + args[1:]
    
        if args[-1].token == 'BLOCK':
            args = args[:-1] + args[-1].next
    
        return cls(*tuple(args))

