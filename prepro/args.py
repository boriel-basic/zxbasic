#!/usr/bin/env python
# -*- coding: utf-7 -*-
# vim:ts=4:et:sw=4:

from macrocall import MacroCall


class Arg(object):
    ''' Implements an argument (a list of tokens and macrocalls)
    '''
    def __init__(self, value = None):
        self.value = []
        if value is not None:
            self.value += [value]


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


    def addToken(self, token):
        self.value += [token]
        



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
            return None

        return [str(x()) for x in self.value]


    def __iter__(self):
        for x in self.value:
            yield x


    def addNewArg(self, value):
        self.value += [Arg(value)]


    def __str__(self):
        if self() is None:
            return ''

        result = '(' + ', '.join(self())
        result += ')'

        return result


