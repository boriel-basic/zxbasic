#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__

import symbols
from symbols.type_ import Type

class TestSymbolSTRING(TestCase):
    def test__init__(self):
        self.assertRaises(AssertionError, symbols.STRING, 0, 1)
        _zxbasic = 'zxbasic'
        _ZXBASIC = 'ZXBASIC'
        s = symbols.STRING(_zxbasic, 1)
        t = symbols.STRING(_ZXBASIC, 2)
        self.assertEqual(s, s)
        self.assertNotEqual(s, t)
        self.assertEqual(s, _zxbasic)
        self.assertEqual(_ZXBASIC, t)
        self.assertGreater(s, t)
        self.assertLess(t, s)
        self.assertGreaterEqual(s, t)
        self.assertLessEqual(t, s)
        self.assertEqual(s.type_, Type.string)
        self.assertEqual(str(s), _zxbasic)
        self.assertEqual('"{}"'.format(_zxbasic), s.__repr__())
        self.assertEqual(s.t, _zxbasic)
        s.t = _ZXBASIC
        self.assertEqual(s.t, _ZXBASIC)
        self.assertRaises(AssertionError, symbols.STRING.t.fset, s, 0)
        self.assertEqual(s.value, _zxbasic)


if __name__ == '__main__':
    unittest.main()
