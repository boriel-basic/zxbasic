#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

from src.api.constants import SCOPE
from src.symbols import sym
from src.symbols.type_ import Type


class TestSymbolVAR(TestCase):
    def setUp(self):
        self.v = sym.ID("v", 1)  # This also tests __init__

    def test__init__fail(self):
        self.assertRaises(AssertionError, sym.ID, "v", 1, None, "blah")  # type_='blah'

    def test_size(self):
        self.assertIsNone(self.v.type_)
        self.v.type_ = Type.byte_
        self.assertEqual(self.v.type_, Type.byte_)

    def test_set_value(self):
        self.v.to_const(sym.NUMBER(1234, lineno=1))
        self.assertEqual(self.v.value, 1234)

    def test_set_value_var(self):
        self.assertRaises(AttributeError, getattr, self.v, "value")

    def test_t(self):
        self.v.to_var()
        self.assertEqual(self.v.scope, SCOPE.global_)  # Must be initialized as global_
        self.assertEqual(self.v.t, self.v.mangled)
        self.v.scope = SCOPE.local
        self.assertEqual(self.v.t, self.v.ref._t)

    def test_t_const(self):
        self.v.to_const(sym.NUMBER(54321, lineno=1))
        self.assertEqual(self.v.t, "54321")

    def test_type_(self):
        self.v.type_ = Type.byte_
        self.assertEqual(self.v.type_, Type.byte_)

    def test_type_fail(self):
        self.assertRaises(AssertionError, sym.ID.type_.fset, self.v, "blah")


if __name__ == "__main__":
    unittest.main()
