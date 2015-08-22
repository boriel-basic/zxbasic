#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:

import collections


class IdentitySet(object):
    """ This set implementation only adds items
    if they are not exactly the same (same reference)
    preserving its order (OrderedDict). Allows deleting by ith-index.
    """
    def __init__(self, L=None):
        self.elems = []
        self._elems = set()
        if L is not None:
            self.add(L)

    def add(self, L):
        if not isinstance(L, collections.Iterable):
            L = [L]
        self.elems.extend(x for x in L)
        self._elems.update(x for x in L)

    def remove(self, L):
        if not isinstance(L, collections.Iterable):
            L = [L]

        self._elems.difference_update(L)
        self.elems = [x for x in self.elems if x not in self._elems]

    def __len__(self):
        return len(self.elems)

    def __getitem__(self, key):
        return self.elems[key]

    def __str__(self):
        return str(self.elems)

    def __contains__(self, elem):
        return elem in self._elems

    def __delitem__(self, key):
        self.pop(self.elems.index(key))

    def pop(self, i):
        tmp = self.elems.pop(i)
        self._elems.remove(tmp)
