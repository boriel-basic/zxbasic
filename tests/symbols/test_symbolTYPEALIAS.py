#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__

from api.constants import TYPE
from symbols.type_ import SymbolBASICTYPE
from symbols.type_ import SymbolTYPEALIAS


class TestSymbolTYPEALIAS(TestCase):
    def test__eq__(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            ta = SymbolTYPEALIAS('alias', 0, t)
            self.assertEqual(t.size, ta.size)
            self.assertTrue(ta == ta)
            self.assertTrue(t == ta)
            self.assertTrue(ta == t)

    def test_is_alias(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            ta = SymbolTYPEALIAS('alias', 0, t)
            self.assertTrue(ta.is_alias)
            self.assertTrue(ta.is_basic)
            self.assertFalse(t.is_alias)


if __name__ == '__main__':
    unittest.main()
