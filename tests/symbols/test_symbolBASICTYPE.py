#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__


from api.constants import TYPE
from symbols.type_ import SymbolBASICTYPE
from symbols.type_ import Type

class TestSymbolBASICTYPE(TestCase):
    def test_size(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            self.assertEqual(t.size, TYPE.size(type_))

    def test_is_basic(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            self.assertTrue(t.is_basic)

    def test_is_dynamic(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            self.assertTrue((type_ == TYPE.string) == t.is_dynamic)

    def test__eq__(self):
        for t_ in TYPE.types:
            t = SymbolBASICTYPE(t_)
            self.assertTrue(t == t)  # test same reference

        for t_ in TYPE.types:
            t1 = SymbolBASICTYPE(t_)
            t2 = SymbolBASICTYPE(t_)
            self.assertTrue(t1 == t2)

        t = SymbolBASICTYPE(TYPE.string)
        self.assertEqual(t, Type.string)

    def test__ne__(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                if t1 == t2:  # Already validated
                    self.assertTrue(t1 == t2)
                else:
                    self.assertTrue(t1 != t2)

    def test_to_signed(self):
        for type_ in TYPE.types:
            if type_ is TYPE.unknown or type_ == TYPE.string:
                continue
            t = SymbolBASICTYPE(type_)
            q = t.to_signed()
            self.assertTrue(q.is_signed)

    def test_bool(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            if t.type_ == TYPE.unknown:
                self.assertFalse(t)
            else:
                self.assertTrue(t)


if __name__ == '__main__':
    unittest.main()
