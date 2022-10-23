#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

from src import symbols
from src.api.constants import CLASS, SCOPE
from src.symbols.type_ import Type


class TestSymbolVAR(TestCase):
    def setUp(self):
        self.v = symbols.VAR("v", 1)  # This also tests __init__

    def test__init__fail(self):
        self.assertRaises(AssertionError, symbols.VAR, "v", 1, None, "blah")  # type_='blah'

    def test_size(self):
        self.assertIsNone(self.v.type_)
        self.v.type_ = Type.byte_
        self.assertEqual(self.v.type_, Type.byte_)

    def test_add_alias(self):
        self.v.add_alias(self.v)

    def test_add_alias_fail(self):
        self.assertRaises(AssertionError, self.v.add_alias, "blah")

    def test_set_value(self):
        self.v.class_ = CLASS.const
        self.v.value = 1234
        self.assertEqual(self.v.value, 1234)

    def test_set_value_var(self):
        self.v.class_ = CLASS.var
        self.assertRaises(AssertionError, getattr, self.v, "value")

    def test_is_aliased(self):
        self.assertFalse(self.v.is_aliased)
        self.v.add_alias(self.v)
        self.assertTrue(self.v.is_aliased)

    def test_t(self):
        self.assertEqual(self.v.scope, SCOPE.global_)  # Must be initialized as global_
        self.assertEqual(self.v.t, self.v.mangled)
        self.v.scope = SCOPE.local
        self.assertEqual(self.v.t, self.v._t)
        self.v.class_ = CLASS.const
        self.v.default_value = 54321
        self.assertEqual(self.v.t, "54321")

    def test_type_(self):
        self.v.type_ = Type.byte_
        self.assertEqual(self.v.type_, Type.byte_)

    def test_type_fail(self):
        self.assertRaises(AssertionError, symbols.VAR.type_.fset, self.v, "blah")


if __name__ == "__main__":
    unittest.main()
