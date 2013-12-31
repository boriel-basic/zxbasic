#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__
from api.constants import TYPE
from symbols.type_ import SymbolTYPE
from symbols.type_ import SymbolBASICTYPE



class TestSymbolTYPE(TestCase):
    def test__eq__(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                t = SymbolTYPE('test_type', 0, t1, t2)
                tt = SymbolTYPE('other_type', 0, t)
                self.assertTrue(t == t)
                self.assertFalse(t != t)
                self.assertTrue(tt == t)
                self.assertTrue(t == tt)
                self.assertTrue(tt == tt)
                self.assertFalse(t != tt)
                self.assertFalse(tt != tt)
                self.assertFalse(tt != t)

    def test_is_basic(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                t = SymbolTYPE('test_type', 0, t1, t2)
                self.assertFalse(t.is_basic)

    def test_is_alias(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                t = SymbolTYPE('test_type', 0, t1, t2)
                self.assertFalse(t.is_alias)


    def test_size(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                t = SymbolTYPE('test_type', 0, t1, t2)
                self.assertEqual(t.size, t1.size + t2.size)


if __name__ == '__main__':
    unittest.main()