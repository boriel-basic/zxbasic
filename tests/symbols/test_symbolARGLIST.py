#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase
import symbols


class TestSymbolARGLIST(TestCase):
    def setUp(self):
        self.VALUE = 5
        self.value = symbols.NUMBER(self.VALUE, 1)
        self.a = symbols.ARGLIST(symbols.ARGUMENT(symbols.NUMBER(self.VALUE, 1), 1))

    def test__len__(self):
        self.assertEqual(len(self.a), 1)
        b = symbols.ARGLIST()
        self.assertEqual(len(b), 0)

    def test_args(self):
        self.assertEqual(self.a[0], self.value)

    def test_args_setter(self):
        self.a[0] = symbols.ARGUMENT(symbols.NUMBER(self.VALUE + 1, 1), 1)
        self.assertEqual(self.a[0], self.value + 1)

    def test_args_setter_fail(self):
        self.assertRaises(AssertionError, symbols.ARGLIST.__setitem__, self.a, 0, 'blah')

    def test_make_node_empty(self):
        b = symbols.ARGLIST.make_node(None)
        self.assertIsInstance(b, symbols.ARGLIST)
        self.assertEqual(len(b), 0)

    def test_make_node_single(self):
        b = symbols.ARGLIST.make_node(symbols.ARGUMENT(symbols.NUMBER(self.VALUE, 1), 1))
        self.assertIsInstance(b, symbols.ARGLIST)
        self.assertEqual(len(b), 1)
        self.assertEqual(b[0], self.value)

    def test_make_node_single2(self):
        b = symbols.ARGLIST.make_node(None, symbols.ARGUMENT(symbols.NUMBER(self.VALUE, 1), 1))
        self.assertIsInstance(b, symbols.ARGLIST)
        self.assertEqual(len(b), 1)
        self.assertEqual(b[0], self.value)

    def test_make_node_fails(self):
        self.assertRaises(AssertionError, symbols.ARGLIST.make_node, 'blah')


if __name__ == '__main__':
    unittest.main()
