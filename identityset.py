#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:

import collections


class IdentitySet(object):
    """ This set implementation only adds items
    if they are not exactly the same (same reference)
    preserving its order (OrderedDict). Allows deleting by ith-index.
    """
    def __init__(self, l=None):
        self.elems = []
        self._elems = set()
        if l is not None:
            self.add(l)

    def add(self, l):
        if not isinstance(l, collections.Iterable):
            l = [l]
        self.elems.extend(x for x in l if x not in self._elems)
        self._elems.update(x for x in l)

    def remove(self, l):
        if not isinstance(l, collections.Iterable):
            l = [l]

        self._elems.difference_update(l)
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

    def intersection(self, other):
        return IdentitySet([x for x in self.elems if x in self._elems.intersection(other)])

    def union(self, other):
        return IdentitySet(self.elems + [x for x in other])

    def pop(self, i):
        tmp = self.elems.pop(i)
        self._elems.remove(tmp)
