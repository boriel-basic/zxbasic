#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__


from api.constants import TYPE
from symbols.type import SymbolBASICTYPE

class TestSymbolBASICTYPE(TestCase):
    def test_size(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(TYPE.to_string(type_), type_)
            self.assertEqual(t.size, TYPE.size(type_))

    def test_is_basic(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(TYPE.to_string(type_), type_)
            self.assertTrue(t.is_basic)


if __name__ == '__main__':
    unittest.main()
