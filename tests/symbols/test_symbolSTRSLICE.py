# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

import src.api.global_ as gl
from src.symbols import sym


class TestSymbolSTRSLICE(TestCase):
    def setUp(self):
        STR = "ZXBASIC"
        self.str_ = sym.STRING(STR, 1)
        self.lower = sym.NUMBER(1, 1, type_=gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE])
        self.upper = sym.NUMBER(2, 1, type_=gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE])

    def test__init__(self):
        sym.STRSLICE(self.str_, self.lower, self.upper, 1)

    def test_string__getter(self):
        s = sym.STRSLICE(self.str_, self.lower, self.upper, 1)
        self.assertEqual(s.string, self.str_)

    def test_string__setter(self):
        s = sym.STRSLICE(self.str_, self.lower, self.upper, 1)
        tmp = sym.STRING(self.str_.value * 2, 1)
        s.string = tmp
        self.assertEqual(s.string, tmp)

    def test_string__setter_fail(self):
        s = sym.STRSLICE(self.str_, self.lower, self.upper, 1)
        self.assertRaises(AssertionError, sym.STRSLICE.string.fset, s, 0)

    def test_lower(self):
        s = sym.STRSLICE(self.str_, self.lower, self.upper, 1)
        self.assertEqual(s.lower, self.lower)

    def test_lower__setter(self):
        s = sym.STRSLICE(self.str_, self.lower, self.upper, 1)
        s.lower = sym.NUMBER(44, 1, type_=gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE])
        self.assertEqual(s.lower, 44)

    def test_upper(self):
        s = sym.STRSLICE(self.str_, self.lower, self.upper, 1)
        self.assertEqual(s.upper, self.upper)

    def test_upper__setter(self):
        s = sym.STRSLICE(self.str_, self.lower, self.upper, 1)
        s.upper = sym.NUMBER(44, 1, type_=gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE])
        self.assertEqual(s.upper, 44)

    def test_make_node(self):
        s = sym.STRSLICE.make_node(1, self.str_, self.lower, self.upper)
        self.assertIsInstance(s, sym.STRING)
        self.assertEqual(s.value, "XB")

    def test_make_node_wrong(self):
        bad_index = sym.ID("a", 0, type_=gl.SYMBOL_TABLE.basic_types[gl.TYPE.string]).to_var()
        s = sym.STRSLICE.make_node(1, self.str_, bad_index, bad_index)
        self.assertIsNone(s)
