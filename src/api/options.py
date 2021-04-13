#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import json

from typing import Dict
from typing import List
from typing import Any
from typing import Tuple

from .errors import Error

__all__ = ['Option', 'Options', 'ANYTYPE']


class ANYTYPE:
    """ Dummy class to signal any value
    """
    pass


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


class InvalidConfigInitialization(Error):
    def __init__(self, invalid_value):
        self.invalid_value = invalid_value

    def __str__(self):
        return "Invalid value for config initialization"


# ----------------------------------------------------------------------
# This class interfaces an Options Container
# ----------------------------------------------------------------------
class Option:
    """ A simple container for options with optional type checking
    on vale assignation.
    """
    def __init__(self, name: str, type_, value=None):
        self.name = name
        self.type = type_
        self.value = value
        self.stack: List[Any] = []  # An option stack

    @property
    def value(self) -> Any:
        return self.__value

    @value.setter
    def value(self, value):
        if value is not None and self.type is not None and not isinstance(value, self.type):
            try:
                if isinstance(value, str) and self.type == bool:
                    value = {
                        'false': False,
                        'true': True,
                        'off': False,
                        'on': True,
                        '-': False,
                        '+': True,
                        'no': False,
                        'yes': True
                    }[value.lower()]
                else:
                    value = self.type(value)
            except TypeError:
                pass
            except ValueError:
                pass
            except KeyError:
                pass

            if value is not None and not isinstance(value, self.type):
                raise InvalidValueError(self.name, self.type, value)

        self.__value = value

    def push(self, value=None):
        if value is None:
            value = self.value

        self.stack.append(self.value)
        self.value = value

    def pop(self) -> Any:
        if not self.stack:
            raise OptionStackUnderflowError(self.name)

        result = self.value
        self.value = self.stack.pop()
        return result


# ----------------------------------------------------------------------
# This class interfaces an Options Container
# ----------------------------------------------------------------------
class Options:
    """ Class to store config options.
    """
    def __init__(self, init_value=None):
        self._options: Dict[str, Option] = {}

        if init_value is not None:
            if isinstance(init_value, dict):
                self._options = init_value
            elif isinstance(init_value, str):
                self._options = json.loads(init_value)
            else:
                raise InvalidConfigInitialization(invalid_value=init_value)

    def reset(self):
        self._options.clear()

    def add_option(self, name, type_=None, default_value=None):
        if name in self._options:
            raise DuplicatedOptionError(name)

        if type_ is None and default_value is not None:
            type_ = type(default_value)
        elif type_ is ANYTYPE:
            type_ = None

        self._options[name] = Option(name, type_, default_value)

    def add_option_if_not_defined(self, name, type_=None, default_value=None):
        if name in self._options:
            return
        self.add_option(name, type_, default_value)

    def __delattr__(self, item: str):
        del self[item]

    def __getattr__(self, item: str):
        return self[item].value

    def __setattr__(self, key: str, value: Any):
        if key == '_options':
            self.__dict__[key] = value
            return

        self[key] = value

    def __getitem__(self, item: str) -> Option:
        if item not in self._options:
            raise UndefinedOptionError(option_name=item)

        return self._options[item]

    def __delitem__(self, item):
        if item not in self._options:
            raise UndefinedOptionError(item)

        del self._options[item]

    def __setitem__(self, key: str, value: Any):
        if key not in self._options:
            raise UndefinedOptionError(option_name=key)

        self._options[key].value = value

    def __contains__(self, item: str):
        return item in self._options

    @classmethod
    def get_options(cls, instance: 'Options') -> List[Tuple[str, Option]]:
        """ Iterate over all options of the given instance
        """
        return list(instance._options.items())
