#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__

import symbols
from symbols.type_ import Type


class TestSymbolVAR(TestCase):
    def setUp(self):
        self.v = symbols.VAR('v', 1)  # This also tests __init__

    def test__init__fail(self):
        self.assertRaises(AssertionError, symbols.VAR, 'v', 1, None, 'blah')  # type_='blah'

    def test_size(self):
        self.assertisNone(self.v.type_)
        self.v.type_ = Type.byte_
        self.assertEqual(self.v.type_, Type.byte_)

    def test_kind(self):
        self.fail()

    def test_set_kind(self):
        self.fail()

    def test_add_alias(self):
        self.fail()

    def test_make_alias(self):
        self.fail()

    def test_is_aliased(self):
        self.fail()

    def test_t(self):
        self.fail()

    def test_type_(self):
        self.fail()

    def test_type_(self):
        self.fail()


if __name__ == '__main__':
    unittest.main()
