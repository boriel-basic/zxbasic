#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:

class IdentitySet(object):
    ''' This set implementation only adds items
    if they are not exactly the same (same reference)
    '''
    def __init__(self, L = []):
        self.elems = []
        self.add(L)

    def add(self, L):
        if not isinstance(L, list):
            L = [L]
        for elem in L:
            if elem not in self:
                self.elems += [elem]

    def remove(self, L):
        if not isinstance(L, list):
            L = [L]

        for elem in L:
            for i in range(len(self.elems)):
                if elem is self.elems[i]:
                    self.pop(i)
                    break

    def __len__(self):
        return len(self.elems)

    def __getitem__(self, key):
        return self.elems[key]

    def __str__(self):
        return str(self.elems)

    def __contains__(self, elem):
        for e in self.elems:
            if e is elem:
                return True

        return False

    def pop(self, i):
        self.elems.pop(i)
    
