#!/usr/bin/env python

from collections.abc import Callable


class classproperty:
    """Decorator for class properties.
    Use @classproperty instead of @property to add properties
    to the class object.
    """

    def __init__(self, fget: Callable[[type], Callable]) -> None:
        self.fget = fget

    def __get__(self, owner_self, owner_cls: type):
        return self.fget(owner_cls)
