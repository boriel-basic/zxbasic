#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

""" Class for a Table of Defines.
Each identifier has a dictionary entry.
"""

import re
import sys
from typing import Dict, Union

from . import output
from .exceptions import PreprocError
from .id_ import ID
from .output import CURRENT_FILE

RE_ID = re.compile(r"[a-zA-Z_][a-zA-Z0-9_]*")


class DefinesTable:
    """A class which will store define labels, and its values.
    It will also replace the current value of a label for the given value.
    """

    def __init__(self):
        """Initializes table"""
        self.table: Dict[str, ID] = {}

    def define(self, id_: str, lineno: int, value: str = "", fname: str = None, args=None):
        """Defines the value of a macro.
        Issues a warning if the macro is already defined.
        """
        if fname is None:
            if CURRENT_FILE:
                fname = CURRENT_FILE[-1]
            else:  # If no files opened yet, use owns program fname
                fname = sys.argv[0]

        if self.defined(id_):
            i = self.table[id_]
            if not i.fname and not i.lineno:  # is this a builtin macro?
                output.warning_overwrite_builtin_macro(lineno=lineno, macro_name=i.name, fname=fname)
            else:
                output.warning_redefined_macro(i.name, i.lineno, i.fname)

        self.set(id_, lineno, value, fname, args)

    def set(self, id_: str, lineno: int, value: str = "", fname: str = None, args=None):
        """Like the above, but issues no warning on duplicate macro
        definitions.
        """
        if fname is None:
            if CURRENT_FILE:
                fname = CURRENT_FILE[-1]
            else:  # If no files opened yet, use owns program fname
                fname = sys.argv[0]
        self.table[id_] = ID(id_, args, value, lineno, fname)

    def undef(self, id_):
        if self.defined(id_):
            del self.table[id_]

    def defined(self, id_: str) -> bool:
        """Returns if the given ID
        is defined
        """
        return id_.strip() in self.table

    def __getitem__(self, key: str) -> Union[str, ID]:
        """Returns the ID instance given it's
        _id. If it does not exist, return the _id
        itself.
        """
        return self.table.get(key.strip(), key)

    def __setitem__(self, key: str, value):
        """Assigns the value to the given table entry"""
        k = key.strip()
        if not RE_ID.match(k):
            raise PreprocError('"%s" must be an identifier' % key, None)
        self.table[key] = value

    def clear(self):
        """Resets macro table"""
        self.table.clear()
