#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

__doc__ = """ A class for an identifier parsed by the preprocessor.
It contains it's name, arguments and macro value.
"""

import sys
import copy

from typing import Optional

from .macrocall import MacroCall
from src.api.debug import __DEBUG__
from .output import CURRENT_FILE
import src.libzxbpp.prepro as prepro

DEBUG_LEVEL = 3  # Which -d level is required to show debug info


class ID:
    """ This class represents an identifier. It stores a string
    (the ID name and value by default).
    """
    __slots__ = 'name', 'value', 'lineno', 'fname', 'args'

    def __init__(self, id_: str, args=None, value=None, lineno: int = None, fname: str = None):
        if fname is None:
            fname = CURRENT_FILE[-1]

        if value is None:
            value = [id_]

        if not isinstance(value, list):
            value = [value]

        self.name: str = id_
        self.value: list = value
        self.lineno: Optional[int] = lineno  # line number at which de ID was defined
        self.fname: str = fname  # file name in which the ID was defined
        self.args = args

    @property
    def hasArgs(self) -> bool:
        return self.args is not None

    def __str__(self):
        return self.name

    @staticmethod
    def __dumptable(table: 'prepro.DefinesTable') -> None:
        """ Dumps table on screen for debugging purposes
        """
        for k, v in table.table.items():
            sys.stdout.write("{0}\t<--- {1} {2}".format(k, v, type(v)))
            if isinstance(v, ID):
                sys.stdout.write(" {0}".format(v.value)),
            sys.stdout.write("\n")

    def __call__(self, table) -> str:
        __DEBUG__("evaluating id '%s'" % self.name, DEBUG_LEVEL)
        if self.value is None:
            __DEBUG__("undefined (null) value. BUG?", DEBUG_LEVEL)
            return ''

        result = ''
        for token in self.value:
            __DEBUG__("evaluating token '%s'" % str(token), DEBUG_LEVEL)
            if isinstance(token, MacroCall):
                __DEBUG__("token '%s'(%s) is a MacroCall" % (token.id_, str(token)), DEBUG_LEVEL)
                if table.defined(token.id_):
                    tmp = table[token.id_]
                    __DEBUG__("'%s' is defined in the symbol table as '%s'" % (token.id_, tmp.name), DEBUG_LEVEL)

                    if isinstance(tmp, ID) and not tmp.hasArgs:
                        __DEBUG__("'%s' is an ID" % tmp.name, DEBUG_LEVEL)
                        token = copy.deepcopy(token)
                        token.id_ = tmp(table)
                        __DEBUG__("'%s' is the new id" % token.id_, DEBUG_LEVEL)

                __DEBUG__("executing MacroCall '%s'" % token.id_, DEBUG_LEVEL)
                tmp = token(table)
            else:
                if isinstance(token, ID):
                    __DEBUG__("token '%s' is an ID" % token.name, DEBUG_LEVEL)
                    token = token(table)
                tmp = token

            __DEBUG__("token got value '%s'" % tmp, DEBUG_LEVEL)
            result += tmp

        return result
