#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:


class IdentitySet:
    """ This set implementation only adds items
    if they are not exactly the same (same reference)
    preserving its order (OrderedDict). Allows deleting by ith-index.
    """
    def __init__(self, elems=None):
        self.elems = []
        self._elems = set()
        self.update(elems or [])

    def add(self, elem):
        self.elems.append(elem)
        self._elems.add(elem)

    def remove(self, elem):
        """ Removes an element if it exits. Otherwise does nothing.
        Returns if the element was removed.
        """
        if elem in self._elems:
            self._elems.remove(elem)
            self.elems = [x for x in self.elems if x in self._elems]
            return True

        return False

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
        return IdentitySet(self._elems.intersection(other))

    def union(self, other):
        return IdentitySet(self.elems + [x for x in other])

    def pop(self, i):
        result = self.elems.pop(i)
        self._elems.remove(result)
        return result

    def update(self, elems):
        self.elems.extend(x for x in elems if x not in self._elems)
        self._elems.update(x for x in elems)
