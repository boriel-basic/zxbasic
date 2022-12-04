#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import enum
import json
from typing import Any, Dict, List

from src.api.exception import Error

__all__ = ["Option", "Options", "ANYTYPE", "Action"]


class ANYTYPE:
    """Dummy class to signal any value"""

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
        return "Invalid value '%s' for option '%s'. Value type must be '%s'" % (self.value, self.option, self.type)


class InvalidConfigInitialization(Error):
    def __init__(self, invalid_value):
        self.invalid_value = invalid_value

    def __str__(self):
        return "Invalid value for config initialization"


class InvalidActionParameterError(Error):
    def __init__(self, action, invalid_parameter):
        self.invalid_parameter = invalid_parameter
        self.action = action

    def __str__(self):
        return f"Action '{self.action}' does not accept parameter '{self.invalid_parameter}'"


class InvalidActionMissingParameterError(Error):
    def __init__(self, action, missing_parameter):
        self.missing_parameter = missing_parameter
        self.action = action

    def __str__(self):
        return f"Action '{self.action}' requires parameter '{self.missing_parameter}'"


# ----------------------------------------------------------------------
# This class interfaces an Options Container
# ----------------------------------------------------------------------
class Option:
    """A simple container for options with optional type checking
    on vale assignation.
    """

    def __init__(self, name: str, type_, value=None, ignore_none=False):
        self.name = name
        self.type = type_
        self.ignore_none = ignore_none
        self.__value = None
        self.value = value
        self.stack: List[Any] = []  # An option stack

    @property
    def value(self) -> Any:
        return self.__value

    @value.setter
    def value(self, value):
        if value is None and self.ignore_none:
            return

        if value is not None and self.type is not None and not isinstance(value, self.type):
            try:
                if isinstance(value, str) and self.type == bool:
                    value = {
                        "false": False,
                        "true": True,
                        "off": False,
                        "on": True,
                        "-": False,
                        "+": True,
                        "no": False,
                        "yes": True,
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
# Options commands
# ----------------------------------------------------------------------
@enum.unique
class Action(str, enum.Enum):
    ADD = "add"
    ADD_IF_NOT_DEFINED = "add_if_not_defined"
    CLEAR = "clear"
    LIST = "list"

    @classmethod
    def valid(cls, action: str) -> bool:
        return action in list(cls)


# ----------------------------------------------------------------------
# This class interfaces an Options Container
# ----------------------------------------------------------------------
class Options:
    """Class to store config options."""

    def __init__(self, init_value=None):
        self._options: Dict[str, Option] = {}

        if init_value is not None:
            if isinstance(init_value, dict):
                self._options = init_value
            elif isinstance(init_value, str):
                self._options = json.loads(init_value)
            else:
                raise InvalidConfigInitialization(invalid_value=init_value)

    def __add_option(self, name, type_=None, default=None, ignore_none=False):
        if name in self._options:
            raise DuplicatedOptionError(name)

        if type_ is None and default is not None:
            type_ = type(default)
        elif type_ is ANYTYPE:
            type_ = None

        self._options[name] = Option(name, type_, default, ignore_none)

    def __add_option_if_not_defined(self, name, type_=None, default=None, ignore_none=False):
        if name in self._options:
            return
        self.__add_option(name, type_, default, ignore_none)

    def __delattr__(self, item: str):
        del self[item]

    def __getattr__(self, item: str):
        return self[item].value

    def __setattr__(self, key: str, value: Any):
        if key == "_options":
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

    def __call__(self, *args, **kwargs):
        """Multipurpose function.
        - With no parameters, returns a dictionary {'option' -> value}
        - With a command:
          'add', name='xxxx', type_=None, default_value=None <= Creates the option 'xxxx', if_not_defined=False
          'reset', clears the container
        """

        def check_allowed_args(action: str, kwargs_, allowed_args, required_args=None):
            for option in kwargs_.keys():
                if option not in allowed_args:
                    raise InvalidActionParameterError(action, option)

            for required_option in required_args or []:
                if required_option not in kwargs_:
                    raise InvalidActionMissingParameterError(action, required_option)

        # With no parameters
        if not kwargs:
            if not args or args == (Action.LIST,):
                return {x: y for x, y in self._options.items()}

        assert args, f"Missing one action of {', '.join(Action)}"
        assert len(args) == 1 and Action.valid(args[0]), f"Only one action of {', '.join(Action)} can be specified"

        # clear
        if args[0] == Action.CLEAR:
            check_allowed_args(Action.CLEAR, kwargs, {})
            self._options.clear()
            return

        # list
        if args[0] == Action.LIST:
            check_allowed_args(Action.LIST, kwargs, {"options"})
            options = set(kwargs["options"])
            return {x: y for x, y in self._options.items() if x in options}

        if args[0] == Action.ADD:
            kwargs["type"] = kwargs.get("type")
            kwargs["default"] = kwargs.get("default")
            kwargs["ignore_none"] = kwargs.get("ignore_none", False)
            check_allowed_args(Action.ADD, kwargs, {"name", "type", "default", "ignore_none"}, ["name"])
            kwargs["type_"] = kwargs["type"]
            del kwargs["type"]
            self.__add_option(**kwargs)
            return

        if args[0] == Action.ADD_IF_NOT_DEFINED:
            kwargs["type"] = kwargs.get("type")
            kwargs["default"] = kwargs.get("default")
            kwargs["ignore_none"] = kwargs.get("ignore_none", False)
            check_allowed_args(Action.ADD, kwargs, {"name", "type", "default", "ignore_none"}, ["name"])
            kwargs["type_"] = kwargs["type"]
            del kwargs["type"]
            self.__add_option_if_not_defined(**kwargs)
