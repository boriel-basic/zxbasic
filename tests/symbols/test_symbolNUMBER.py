#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

from api.constants import TYPE
from symbols import NUMBER
from symbols import BASICTYPE
from symbols import CONST


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

    def test__cmp__const(self):
        n = NUMBER(0, lineno=1)
        m = CONST(NUMBER(1, lineno=2), lineno=2)
        m2 = CONST(NUMBER(0, lineno=3), lineno=3)

        self.assertNotEqual(n, m)
        self.assertEqual(n, n)

        self.assertNotEqual(n, 2)
        self.assertEqual(n, 0)
        self.assertGreater(n, -1)
        self.assertLess(n, 1)

        self.assertGreater(m, n)
        self.assertLess(n, m)
        self.assertEqual(n, m2)
        self.assertEqual(m2, n)

    def test__t(self):
        n = NUMBER(3.14, 1)
        self.assertEqual(n.t, '3.14')

    def test__add__num_num(self):
        a = NUMBER(1, 0)
        b = NUMBER(2, 0)
        self.assertEqual((a + b).t, '3')

    def test__add__num_const(self):
        a = NUMBER(1, 0)
        b = CONST(NUMBER(2, 0), 0)
        self.assertEqual((a + b).t, '3')

    def test__add__num_value(self):
        a = NUMBER(1, 0)
        self.assertEqual((a + 2).t, '3')

    def test__radd__num_const(self):
        a = NUMBER(1, 0)
        b = CONST(NUMBER(2, 0), 0)
        self.assertEqual((b + a).t, '3')

    def test__radd__num_value(self):
        a = NUMBER(1, 0)
        self.assertEqual((2 + a).t, '3')

    def test__sub__num_num(self):
        a = NUMBER(1, 0)
        b = NUMBER(2, 0)
        self.assertEqual((a - b).t, '-1')

    def test__sub__num_const(self):
        a = NUMBER(1, 0)
        b = CONST(NUMBER(2, 0), 0)
        self.assertEqual((a - b).t, '-1')

    def test__sub__num_value(self):
        a = NUMBER(1, 0)
        self.assertEqual((a - 2).t, '-1')

    def test__rsub__num_const(self):
        a = NUMBER(2, 0)
        b = CONST(NUMBER(1, 0), 0)
        self.assertEqual((b - a).t, '-1')

    def test__rsub__num_value(self):
        a = NUMBER(2, 0)
        self.assertEqual((1 - a).t, '-1')

    def test__mul__num_num(self):
        a = NUMBER(3, 0)
        b = NUMBER(2, 0)
        self.assertEqual((a * b).t, '6')

    def test__mul__num_const(self):
        a = NUMBER(3, 0)
        b = CONST(NUMBER(2, 0), 0)
        self.assertEqual((a * b).t, '6')

    def test__mul__num_value(self):
        a = NUMBER(3, 0)
        self.assertEqual((a * 2).t, '6')

    def test__rmul__num_const(self):
        a = NUMBER(3, 0)
        b = CONST(NUMBER(2, 0), 0)
        self.assertEqual((b * a).t, '6')

    def test__rmul__num_value(self):
        a = NUMBER(3, 0)
        self.assertEqual((2 * a).t, '6')

    def test__div__num_num(self):
        a = NUMBER(3, 0)
        b = NUMBER(-2, 0)
        self.assertEqual((a / b).t, str(a.value / b.value))

    def test__div__num_const(self):
        a = NUMBER(3, 0)
        b = CONST(NUMBER(-2, 0), 0)
        self.assertEqual((a / b).t, str(a.value / b.expr.value))

    def test__div__num_value(self):
        a = NUMBER(3, 0)
        self.assertEqual((a / -2.0).t, '-1.5')

    def test__rdiv__num_const(self):
        a = CONST(NUMBER(-3, 0), 0)
        b = NUMBER(2, 0)
        self.assertEqual((a / b).t, str(a.expr.value / b.value))

    def test__rdiv__num_value(self):
        a = NUMBER(-2, 0)
        self.assertEqual((3.0 / a).t, '-1.5')

    def test__bor__val_num(self):
        b = NUMBER(5, 0)
        self.assertEqual((3 | b).t, '7')

    def test__bor__num_val(self):
        b = NUMBER(5, 0)
        self.assertEqual((b | 3).t, '7')

    def test__band__num_val(self):
        b = NUMBER(5, 0)
        self.assertEqual((b & 3).t, '1')

    def test__band__val_num(self):
        b = NUMBER(5, 0)
        self.assertEqual((3 & b).t, '1')

    def test__mod__num_val(self):
        b = NUMBER(5, 0)
        self.assertEqual((b % 3).t, '2')

    def test__mod__val_num(self):
        b = NUMBER(3, 0)
        self.assertEqual((5 % b).t, '2')

    def test__le__val_num(self):
        b = NUMBER(3, 0)
        self.assertLessEqual(2, b)

    def test__le__num_num(self):
        a = NUMBER(2, 0)
        b = NUMBER(3, 0)
        self.assertLessEqual(a, b)

    def test__ge__val_num(self):
        b = NUMBER(1, 0)
        self.assertGreaterEqual(2, b)

    def test__ge__num_num(self):
        a = NUMBER(4, 0)
        b = NUMBER(3, 0)
        self.assertGreaterEqual(a, b)


if __name__ == '__main__':
    unittest.main()
