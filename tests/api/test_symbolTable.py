#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase
from StringIO import StringIO

# Initialize import syspath
import __init__

from api.symboltable import SymbolTable
from api.constants import TYPE
from api.constants import SCOPE
from api.config import OPTIONS

from symbols.type_ import SymbolTYPE
from symbols.type_ import SymbolBASICTYPE
from symbols.var import SymbolVAR

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

    def test_is_declared(self):
        s = SymbolTable()
        # Checks variable 'a' is not declared yet
        self.assertFalse(s.check_is_declared('a', 0, 'var', show_error=False))
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        # Checks variable 'a' is declared
        self.assertTrue(s.check_is_declared('a', 1, 'var', show_error=False))

    def test_is_undeclared(self):
        s = SymbolTable()
        # Checks variable 'a' is undeclared
        self.assertTrue(s.check_is_undeclared('a', 10, show_error=False))
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        # Checks variable 'a' is not undeclared
        self.assertFalse(s.check_is_undeclared('a', 10, show_error=False))

    def test_declare_variable(self):
        self.clearOutput()
        s = SymbolTable()
        # Declares 'a' (integer) variable
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        # Now checks for duplicated name 'a'
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        self.assertEqual(self.OUTPUT,
                         "(stdin):10: Variable 'a' already declared at (stdin):10\n")

        # Checks for duplicated var name using suffixes
        self.clearOutput()
        s.declare_variable('a%', 11, s.basic_types[TYPE.to_string(TYPE.integer)])
        self.assertEqual(self.OUTPUT,
                         "(stdin):11: Variable 'a%' already declared at (stdin):10\n")

        self.clearOutput()
        s.declare_variable('b%', 12, s.basic_types[TYPE.to_string(TYPE.byte_)])
        self.assertEqual(self.OUTPUT,
                         "(stdin):12: 'b%' suffix is for type 'integer' but it was declared as 'byte'\n")


    def test_get_entry(self):
        s = SymbolTable()
        var_a = s.get_entry('a')
        self.assertIsNone(var_a)
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        var_a = s.get_entry('a')
        self.assertIsNotNone(var_a)
        self.assertIsInstance(var_a, SymbolVAR)
        self.assertEqual(var_a.scope, SCOPE.global_)


    def test_start_function_body(self):
        self.clearOutput()
        s = SymbolTable()
        # Declares a variable named 'a'
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        s.start_function_body('testfunction')
        self.assertNotEqual(s.current_scope, s.global_scope)
        self.assertTrue(s.check_is_undeclared('a', 11, scope=s.current_scope))

        # Now checks for duplicated name 'a'
        s.declare_variable('a', 12, s.basic_types[TYPE.to_string(TYPE.float_)])
        self.assertTrue(s.check_is_declared('a', 11, scope=s.current_scope))
        var_a = s.get_entry('a')
        self.assertEqual(var_a.scope, SCOPE.local)

        # Now checks for duplicated name 'a'
        s.declare_variable('a', 14, s.basic_types[TYPE.to_string(TYPE.float_)])
        self.assertEqual(self.OUTPUT,
                        "(stdin):14: Variable 'a' already declared at (stdin):12\n")

    def test_end_function_body(self):
        self.clearOutput()
        s = SymbolTable()
        s.start_function_body('testfunction')
        # Declares a variable named 'a'
        s.declare_variable('a', 10, s.basic_types[TYPE.to_string(TYPE.integer)])
        s.end_function_body()

        # Now checks for duplicated name 'a'
        self.assertTrue(s.check_is_undeclared('a', 10))
        s.declare_variable('a', 12, s.basic_types[TYPE.to_string(TYPE.float_)])
        var_a = s.get_entry('a')


    def clearOutput(self):
        OPTIONS.stderr.value = StringIO()

    @property
    def OUTPUT(self):
        return OPTIONS.stderr.value.getvalue()


if __name__ == '__main__':
    OPTIONS.remove_option('stderr')
    OPTIONS.add_option('stderr', default_value=StringIO())
    unittest.main()
