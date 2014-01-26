#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase
from symbols import BLOCK
from symbols import NUMBER

# Initialize import syspath
import __init__

__author__ = 'boriel'


class TestSymbolBLOCK(TestCase):
    def test_make_node_empty(self):
        BLOCK.make_node()

    def test_make_node_empty2(self):
        b = BLOCK.make_node(None, None)
        self.assertEqual(b, BLOCK())

    def test_make_node_simple(self):
        b = BLOCK.make_node(NUMBER(1, lineno=1))
        self.assertIsInstance(b, BLOCK)

    def test__len__(self):
        b = BLOCK.make_node(NUMBER(1, lineno=1))
        self.assertEqual(len(b), 1)

    def test__getitem__0(self):
        n = NUMBER(1, lineno=1)
        b = BLOCK.make_node(n)
        self.assertEqual(b[0], n)

    def test_getitem__error(self):
        n = NUMBER(1, lineno=1)
        b = BLOCK.make_node(n)
        self.assertRaises(IndexError, b.__getitem__, len(b))

    def test_make_node_wrong(self):
        self.assertRaises(AssertionError, BLOCK.make_node, 1)

    def test_make_node_optimize1(self):
        b = BLOCK.make_node(BLOCK(NUMBER(1, lineno=1)))
        self.assertIsInstance(b[0], NUMBER)

    def test_make_node_optimize2(self):
        n = NUMBER(1, lineno=1)
        b = BLOCK.make_node(BLOCK(n), n, BLOCK(n))
        self.assertEqual(len(b), 3)
        for x in b:
            self.assertIsInstance(x, NUMBER)

    def test__eq__(self):
        b = BLOCK()
        self.assertEqual(b, b)
        q = BLOCK()
        self.assertEqual(b, q)

    def test__eq__2(self):
        n = NUMBER(1, lineno=1)
        b = BLOCK.make_node(n)
        self.assertEqual(b, b)
        q = BLOCK()
        self.assertNotEqual(b, q)
        self.assertNotEqual(q, None)
        self.assertNotEqual(None, q)
        self.assertNotEqual(q, 'STRING')
