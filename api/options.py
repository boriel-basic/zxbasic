#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from .errors import Error

TRUE = true = True
FALSE = false = False


__all__ = ['Option', 'Options']

# ----------------------------------------------------------------------
# Exception for duplicated Options
# ----------------------------------------------------------------------


class DuplicatedOptionError(Error):
    def __init__(self, option_name):
        self.option = option_name

    def __str__(self):
        return "Option '%s' already defined" % self.option


class UndefinedOptionError(Error):
    def __init__(self, option_name):
        self.option = option_name

    def __str__(self):
        return "Undefined option '%s'" % self.option


class OptionStackUnderflowError(Error):
    def __init__(self, option_name):
        self.option = option_name

    def __str__(self):
        return "Cannot pop option '%s'. Option stack is empty" % self.option


class InvalidValueError(Error):
    def __init__(self, option_name, _type, value):
        self.option = option_name
        self.value = value
        self.type = _type

    def __str__(self):
        return "Invalid value '%s' for option '%s'. Value type must be '%s'" \
            % (self.value, self.option, self.type)


# ----------------------------------------------------------------------
# This class interfaces an Options Container
# ----------------------------------------------------------------------
class Option(object):
    ''' A simple container
    '''
    def __init__(self, name, type_, value=None):
        self.name = name
        self.type = type_
        self.value = value
        self.stack = []  # An option stack

    @property
    def value(self):
        return self.__value

    @value.setter
    def value(self, value):
        if self.type is not None:
            try:
                value = eval(value)
            except:
                pass

            if value is not None and not isinstance(value, self.type):
                raise InvalidValueError(self.name, self.type, value)

        self.__value = value

    def push(self, value=None):
        if value is None:
            value = self.value

        self.stack.append(self.value)
        self.value = value

    def pop(self):
        result = self.value

        try:
            self.value = self.stack.pop()
        except IndexError:
            raise OptionStackUnderflowError(self.name)

        return result


# ----------------------------------------------------------------------
# This class interfaces an Options Container
# ----------------------------------------------------------------------
class Options(object):
    def __init__(self):
        self.options = {}

    def add_option(self, name, type_=None, default_value=None):
        if name in self.options.keys():
            raise DuplicatedOptionError(name)

        if type_ is None and default_value is not None:
            type_ = type(default_value)

        self.options[name] = Option(name, type_, default_value)
        setattr(self, name, self.options[name])

    def has_option(self, name):
        ''' Returns whether the given option is defined in this class.
        '''
        return hasattr(self, name)

    def add_option_if_not_defined(self, name, type_=None, default_value=None):
        if self.has_option(name):
            return
        self.add_option(name, type_, default_value)

    def remove_option(self, name):
        if name not in self.options.keys():
            raise UndefinedOptionError(name)

        del self.options[name]
        delattr(self, name)

    def option(self, name):
        if name not in self.options.keys():
            raise UndefinedOptionError(name)

        return self.options[name]
