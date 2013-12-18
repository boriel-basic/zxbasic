#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__


from api.constants import TYPE
from symbols.type_ import SymbolBASICTYPE

class TestSymbolBASICTYPE(TestCase):
    def test_size(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(TYPE.to_string(type_), type_)
            self.assertEqual(t.size, TYPE.size(type_))

    def test_is_basic(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(TYPE.to_string(type_), type_)
            self.assertTrue(t.is_basic)

    def test__eq__(self):
        for t_ in TYPE.types:
            t = SymbolBASICTYPE(TYPE.to_string(t_), t_)
            self.assertTrue(t == t)  # test same reference

        for t_ in TYPE.types:
            t1 = SymbolBASICTYPE(TYPE.to_string(t_), t_)
            t2 = SymbolBASICTYPE(TYPE.to_string(t_), t_)
            self.assertTrue(t1 == t2)

    def test__ne__(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(TYPE.to_string(t1_), t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(TYPE.to_string(t2_), t2_)
                if t1 == t2:  # Already validated
                    self.assertTrue(t1 == t2)
                else:
                    self.assertTrue(t1 != t2)


if __name__ == '__main__':
    unittest.main()
