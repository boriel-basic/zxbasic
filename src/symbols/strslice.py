#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4:et:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

import src.api.check as check
import src.api.config as config
import src.api.global_ as gl
from src.symbols.binary import SymbolBINARY as BINARY
from src.symbols.number import SymbolNUMBER as NUMBER
from src.symbols.string_ import SymbolSTRING as STRING
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import Type
from src.symbols.typecast import SymbolTYPECAST as TYPECAST


class SymbolSTRSLICE(Symbol):
    """Defines a string slice"""

    def __init__(self, string, lower, upper, lineno):
        super().__init__(string, lower, upper)
        self.string = string  # Ensures is STRING via setter
        self.lower = lower
        self.upper = upper
        self.lineno = lineno
        self.type_ = Type.string

    @property
    def string(self):
        return self.children[0]

    @string.setter
    def string(self, value):
        assert isinstance(value, Symbol)
        assert value.type_ == Type.string
        self.children[0] = value

    @property
    def lower(self):
        return self.children[1]

    @lower.setter
    def lower(self, value):
        assert isinstance(value, Symbol)
        assert value.type_ == gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE]
        self.children[1] = value  # TODO: typecast it to UINTEGER ??

    @property
    def upper(self):
        return self.children[2]

    @upper.setter
    def upper(self, value):
        assert isinstance(value, Symbol)
        assert value.type_ == gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE]
        self.children[2] = value

    @classmethod
    def make_node(cls, lineno: int, s, lower, upper):
        """Creates a node for a string slice. S is the string expression Tree.
        Lower and upper are the bounds, if lower & upper are constants, and
        s is also constant, then a string constant is returned.

        If lower > upper, an empty string is returned.
        """
        if lower is None or upper is None or s is None:
            return None

        if not check.check_type(lineno, Type.string, s):
            return None

        lo = up = None
        base = NUMBER(config.OPTIONS.string_base, lineno=lineno)
        lower = TYPECAST.make_node(
            gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE],
            BINARY.make_node("MINUS", lower, base, lineno=lineno, func=lambda x, y: x - y),
            lineno,
        )
        upper = TYPECAST.make_node(
            gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE],
            BINARY.make_node("MINUS", upper, base, lineno=lineno, func=lambda x, y: x - y),
            lineno,
        )

        if lower is None or upper is None:
            return None

        if check.is_number(lower):
            lo = lower.value
            if lo < gl.MIN_STRSLICE_IDX:
                lower.value = lo = gl.MIN_STRSLICE_IDX

        if check.is_number(upper):
            up = upper.value
            if up > gl.MAX_STRSLICE_IDX:
                upper.value = up = gl.MAX_STRSLICE_IDX

        if check.is_number(lower, upper):
            if lo > up:
                return STRING("", lineno)

            if s.token == "STRING":  # A constant string? Recalculate it now
                up += 1
                st = s.value.ljust(up)  # Procrustean filled (right)
                return STRING(st[lo:up], lineno)

            # a$(0 TO INF.) = a$
            if lo == gl.MIN_STRSLICE_IDX and up == gl.MAX_STRSLICE_IDX:
                return s

        return cls(s, lower, upper, lineno)
