#!/usr/bin/env python
# -*- coding: utf-8 -*-


class classproperty:
    """ Decorator for class properties.
    Use @classproperty instead of @property to add properties
    to the class object.
    """
    def __init__(self, fget):
        self.fget = fget

    def __get__(self, owner_self, owner_cls):
        return self.fget(owner_cls)
