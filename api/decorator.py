#!/usr/bin/env python
# -*- coding: utf-8 -*-

import collections
import inspect
import os


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
    args = tuple(x if isinstance(x, collections.Iterable) else (x,) for x in args)
    kwargs = {x: kwargs[x] if isinstance(kwargs[x], collections.Iterable) else (kwargs[x],) for x in kwargs}

    def decorate(func):
        types = args
        kwtypes = kwargs
        gi = "Got <{}> instead"
        errmsg1 = "to be of type <{}>. " + gi
        errmsg2 = "to be one of type ({}). " + gi
        errar = "{}:{} expected '{}' "
        errkw = "{}:{} expected {} "

        def check(*ar, **kw):
            line = inspect.getouterframes(inspect.currentframe())[1][2]
            fname = os.path.basename(inspect.getouterframes(inspect.currentframe())[1][1])

            for arg, type_ in zip(ar, types):
                if type(arg) not in type_:
                    if len(type_) == 1:
                        raise TypeError((errar + errmsg1).format(fname, line, arg, type_[0].__name__,
                                                                 type(arg).__name__))
                    else:
                        raise TypeError((errar + errmsg2).format(fname, line, arg,
                                                                 ', '.join('<%s>' % x.__name__ for x in type_),
                                                                 type(arg).__name__))
            for kwarg in kw:
                if kwtypes.get(kwarg, None) is None:
                    continue
                if type(kw[kwarg]) not in kwtypes[kwarg]:
                    if len(kwtypes[kwarg]) == 1:
                        raise TypeError((errkw + errmsg1).format(fname, line, kwarg, kwtypes[kwarg][0].__name__,
                                                                 type(kw[kwarg]).__name__))
                    else:
                        raise TypeError((errkw + errmsg2).format(fname, line, kwarg,
                                                                 ', '.join('<%s>' % x.__name__
                                                                                  for x in kwtypes[kwarg]),
                                                                 type(kw[kwarg]).__name__))

            return func(*ar, **kw)

        return check

    return decorate


