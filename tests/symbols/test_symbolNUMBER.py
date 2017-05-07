#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__

from api.constants import TYPE
from symbols import NUMBER
from symbols import BASICTYPE


class TestSymbolNUMBER(TestCase):
    def test__init__(self):
        self.assertRaises(AssertionError, NUMBER, 0, lineno=None)
        self.assertRaises(AssertionError, NUMBER, 0, lineno=1, type_='')

        n = NUMBER(0, lineno=1)
        self.assertEqual(n.type_, BASICTYPE(TYPE.ubyte))

        n = NUMBER(-1, lineno=1)
        self.assertEqual(n.type_, BASICTYPE(TYPE.byte_))

        n = NUMBER(256, lineno=1)
        self.assertEqual(n.type_, BASICTYPE(TYPE.uinteger))

        n = NUMBER(-256, lineno=1)
        self.assertEqual(n.type_, BASICTYPE(TYPE.integer))

    def test__cmp__(self):
        n = NUMBER(0, lineno=1)
        m = NUMBER(1, lineno=2)

        self.assertNotEqual(n, m)
        self.assertEqual(n, n)

        self.assertNotEqual(n, 2)
        self.assertEqual(n, 0)
        self.assertGreater(n, -1)
        self.assertLess(n, 1)

        self.assertGreater(m, n)
        self.assertLess(n, m)

    def test__t(self):
        n = NUMBER(3.14, 1)
        self.assertEqual(n.t, '3.14')


if __name__ == '__main__':
    unittest.main()
