#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__
import symbols
import api.global_ as gl


class TestSymbolSTRSLICE(TestCase):
    @classmethod
    def setUpClass(cls):
        import arch.zx48k  # Initializes zx48k arch

    def setUp(self):
        STR = "ZXBASIC"
        self.str_ = symbols.STRING(STR, 1)
        self.lower = symbols.NUMBER(1, 1, type_=gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE])
        self.upper = symbols.NUMBER(2, 1, type_=gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE])

    def test__init__(self):
        s = symbols.STRSLICE(self.str_, self.lower, self.upper, 1)

    def test_string__getter(self):
        s = symbols.STRSLICE(self.str_, self.lower, self.upper, 1)
        self.assertEqual(s.string, self.str_)

    def test_string__setter(self):
        s = symbols.STRSLICE(self.str_, self.lower, self.upper, 1)
        tmp = symbols.STRING(self.str_.value * 2, 1)
        s.string = tmp
        self.assertEqual(s.string, tmp)

    def test_string__setter_fail(self):
        s = symbols.STRSLICE(self.str_, self.lower, self.upper, 1)
        self.assertRaises(AssertionError, symbols.STRSLICE.string.fset, s, 0)

    def test_lower(self):
        s = symbols.STRSLICE(self.str_, self.lower, self.upper, 1)
        self.assertEqual(s.lower, self.lower)

    def test_lower__setter(self):
        s = symbols.STRSLICE(self.str_, self.lower, self.upper, 1)
        s.lower = symbols.NUMBER(44, 1, type_=gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE])
        self.assertEqual(s.lower, 44)

    def test_upper(self):
        s = symbols.STRSLICE(self.str_, self.lower, self.upper, 1)
        self.assertEqual(s.upper, self.upper)

    def test_upper__setter(self):
        s = symbols.STRSLICE(self.str_, self.lower, self.upper, 1)
        s.upper = symbols.NUMBER(44, 1, type_=gl.SYMBOL_TABLE.basic_types[gl.STR_INDEX_TYPE])
        self.assertEqual(s.upper, 44)

    def test_make_node(self):
        s = symbols.STRSLICE.make_node(1, self.str_, self.lower, self.upper)
        self.assertIsInstance(s, symbols.STRING)
        self.assertEqual(s.value, 'XB')


if __name__ == '__main__':
    unittest.main()
