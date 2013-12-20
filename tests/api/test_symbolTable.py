#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__

from api.symboltable import SymbolTable
from api.constants import TYPE
from symbols.type_ import SymbolTYPE
from symbols.type_ import SymbolBASICTYPE

class TestSymbolTable(TestCase):
    def test__init__(self):
        ''' Tests symbol table initialization
        '''
        s = SymbolTable()
        self.assertEqual(len(s.types), len(TYPE.types))
        for type_ in s.types:
            self.assertTrue(type_.is_basic)
            self.assertIsInstance(type_, SymbolBASICTYPE)

        self.assertEqual(s.current_scope, s.global_scope)



if __name__ == '__main__':
    unittest.main()