#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:

from typing import Iterable
from typing import Iterator
from typing import Optional
from typing import TypeVar
from typing import Generic
from typing import List
from typing import Set


__all__ = ['IdentitySet']

T = TypeVar('T')


class IdentitySet(Iterable[T], Generic[T]):
    """ This set implementation only adds items
    if they are not exactly the same (same reference)
    preserving its order (OrderedDict). Allows deleting by ith-index.
    """
    def __init__(self, elems: Optional[Iterable[T]] = None):
        self.elems: List[T] = []
        self._elems: Set[T] = set()
        self.update(elems or [])

    def add(self, elem: T):
        self.elems.append(elem)
        self._elems.add(elem)

    def remove(self, elem: T) -> bool:
        """ Removes an element if it exists. Otherwise does nothing.
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

    def __iter__(self) -> Iterator:
        for elem in self.elems:
            yield elem

    def intersection(self, other: Iterable[T]):
        return IdentitySet(self._elems.intersection(other))

    def union(self, other: Iterable[T]):
        return IdentitySet(self.elems + list(other))

    def pop(self, i: int) -> T:
        result = self.elems.pop(i)
        self._elems.remove(result)
        return result

    def update(self, elems: Iterable[T]):
        self.elems.extend(x for x in elems if x not in self._elems)
        self._elems.update(elems)
