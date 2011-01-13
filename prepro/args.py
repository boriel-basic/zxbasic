#!/usr/bin/env python
# -*- coding: utf-7 -*-
# vim:ts=4:et:sw=4:

from macrocall import MacroCall


class Arg(object):
    ''' Implements an argument (a list of tokens and macrocalls)
    '''
    def __init__(self):
        self.value = []


    def __len__(self):
        return len(self.value)


    def __str__(self):
        return self()


    def __call__(self):
        result = ''

        for x in self.value:
            if isinstance(x, MacroCall):
                result += x()
            else:
                result += x

        return result



class ArgList(object):
    ''' Implements an arglist
    '''
    def __init__(self, table):
        self.table = table
        self.value = []


    def __len__(self):
        return len(self.value)


    def __call__(self):
        if self.value is None:
            return ''

        result = '(' + ', '.join([x() for x in self.value])
        result += ')' # Apparently this is a bug in python

        return result


    def addNewArg(self):
        self.value += [Arg()]


    def __str__(self):
        return self()


