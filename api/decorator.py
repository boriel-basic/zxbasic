#!/usr/bin/env python
# -*- coding: utf-8 -*-

import collections


class classproperty(object):
    ''' Decorator for class properties.
    Use @classproperty instead of @property to add properties
    to the class object.
    '''
    def __init__(self, fget):
        self.fget = fget

    def __get__(self, owner_self, owner_cls):
        return self.fget(owner_cls)


def check_type(*args, **kwargs):
    ''' Checks the function types
    '''
    args = (x if isinstance(x, collections.Iterable) else (x,) for x in args)
    kwargs = {x: kwargs[x] if isinstance(kwargs[x], collections.Iterable) else (kwargs[x],) for x in kwargs}

    def decorate(func):
        types = args
        kwtypes = kwargs

        def check(*ar, **kw):
            for arg, type_ in zip(ar, types):
                if type(arg) not in type_:
                    if len(type_) > 1:
                        raise TypeError("Expected '{}' to be one of type {}. "
                                        "Got {} instead".format(arg, tuple(type_), type(arg)))
                    else:
                        raise TypeError("Expected '{}' to be of type {}. "
                                        "Got {} instead".format(arg, type_[0], type(arg)))
            for kwarg in kw:
                if kwtypes.get(kwarg, None) is None:
                    continue

                if type(kw[kwarg]) not in kwtypes[kwarg]:
                    if len(kwtypes[kwarg]) > 1:
                        raise TypeError("Expected parameter {} to be one of type {}. "
                                        "Got {} instead".format(kwarg, tuple(kwtypes[kwarg]), type(kw[kwarg])))
                    else:
                        raise TypeError("Expected parameter {} to be of type {}. "
                                        "Got {} instead".format(kwarg, kwtypes[kwarg][0], type(kw[kwarg])))

            return func(*ar, **kw)

        return check

    return decorate

