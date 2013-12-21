#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase
from StringIO import StringIO

# Initialize import syspath
import __init__

from api.symboltable import SymbolTable
from api.constants import TYPE
from api.config import OPTIONS
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

    def test_declare_variable(self):
        OPTIONS.stderr.value = StringIO()
        s = SymbolTable()
        # Checks variable 'a' is not declared yet
        self.assertFalse(s.check_is_declared('a', 0, 'var', show_error=False))
        # Checks variable 'a' is undeclared
        self.assertTrue(s.check_is_undeclared('a', show_error=False))

        # Declares a variable named 'a' (produces duplicated name error)
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        # Checks variable 'a' is declared
        self.assertTrue(s.check_is_declared('a', 1, 'var', show_error=False))
        # Checks variable 'a' is not undeclared
        self.assertFalse(s.check_is_undeclared('a', show_error=False))
        # Now checks for duplicated name 'a'
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        self.assertEqual(OPTIONS.stderr.value.getvalue(),
                         "(stdin):10: Variable 'a' already declared at (stdin):10\n")

    def test_nested_scope(self):
        s = SymbolTable()
         # Declares a variable named 'a'
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        s.start_function_body('testfunction')
        # Now checks for duplicated name 'a'
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.float_)])


if __name__ == '__main__':
    OPTIONS.remove_option('stderr')
    OPTIONS.add_option('stderr', default_value=StringIO())
    unittest.main()
