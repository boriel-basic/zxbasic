#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase
from six import StringIO

# Initialize import syspath
import __init__

from api.config import OPTIONS
import symbols

class TestSymbolBOUND(TestCase):
    def test__init__(self):
        self.assertRaises(AssertionError, symbols.BOUND, 'a', 3)
        self.assertRaises(AssertionError, symbols.BOUND, 1, 'a')
        self.assertRaises(AssertionError, symbols.BOUND, 3, 1)

    def test_count(self):
        lower = 1
        upper = 3
        b = symbols.BOUND(lower, upper)
        self.assertEqual(b.count, upper - lower + 1)

    def test_make_node(self):
        self.clearOutput()
        l = symbols.NUMBER(2, lineno=1)
        u = symbols.NUMBER(3, lineno=2)
        b = symbols.BOUND.make_node(l, u, 3)
        self.assertEqual(self.stderr, '')

        l = symbols.NUMBER(4, lineno=1)
        b = symbols.BOUND.make_node(l, u, 3)
        self.assertEqual(self.stderr, '(stdin):3: Lower array bound must be less or equal to upper one\n')

        self.clearOutput()
        l = symbols.NUMBER(-4, lineno=1)
        b = symbols.BOUND.make_node(l, u, 3)
        self.assertEqual(self.stderr, '(stdin):3: Array bounds must be greater than 0\n')

        self.clearOutput()
        l = symbols.VAR('a', 10)
        b = symbols.BOUND.make_node(l, u, 3)
        self.assertEqual(self.stderr, '(stdin):3: Array bounds must be constants\n')

    def test__str__(self):
        b = symbols.BOUND(1, 3)
        self.assertEqual(str(b), '(1 TO 3)')

    def test__repr__(self):
        b = symbols.BOUND(1, 3)
        self.assertEqual(b.__repr__(), b.token + '(1 TO 3)')


    def clearOutput(self):
        OPTIONS.remove_option('stderr')
        OPTIONS.add_option('stderr', default_value=StringIO())

    @property
    def stderr(self):
        return OPTIONS.stderr.value.getvalue()




if __name__ == '__main__':
    unittest.main()
