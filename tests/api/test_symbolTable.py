#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase
from six import StringIO

# Initialize import syspath
import __init__

from api.symboltable import SymbolTable
from api.constants import TYPE
from api.constants import SCOPE
from api.constants import CLASS
from api.constants import DEPRECATED_SUFFIXES
from api.config import OPTIONS
import api.global_ as gl_
import symbols


class TestSymbolTable(TestCase):
    def setUp(self):
        self.clearOutput()
        self.s = gl_.SYMBOL_TABLE = SymbolTable()
        l1, l2, l3, l4 = 1, 2, 3, 4
        b = symbols.BOUND(l1, l2)
        c = symbols.BOUND(l3, l4)
        self.bounds = symbols.BOUNDLIST.make_node(None, b, c)
        self.func = symbols.FUNCDECL.make_node('testfunction', 1)

    def test__init__(self):
        ''' Tests symbol table initialization
        '''
        self.assertEqual(len(self.s.types), len(TYPE.types))
        for type_ in self.s.types:
            self.assertTrue(type_.is_basic)
            self.assertIsInstance(type_, symbols.BASICTYPE)

        self.assertEqual(self.s.current_scope, self.s.global_scope)

    def test_is_declared(self):
        # Checks variable 'a' is not declared yet
        self.assertFalse(self.s.check_is_declared('a', 0, 'var', show_error=False))
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        # Checks variable 'a' is declared
        self.assertTrue(self.s.check_is_declared('a', 1, 'var', show_error=False))

    def test_is_undeclared(self):
        s = SymbolTable()
        # Checks variable 'a' is undeclared
        self.assertTrue(s.check_is_undeclared('a', 10, show_error=False))
        s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        # Checks variable 'a' is not undeclared
        self.assertFalse(s.check_is_undeclared('a', 10, show_error=False))

    def test_declare_variable(self):
        # Declares 'a' (integer) variable
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        self.assertIsNotNone(self.s[self.s.current_scope]['a'])

    def test_declare_variable_dupl(self):
        # Declares 'a' (integer) variable
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        # Now checks for duplicated name 'a'
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        self.assertEqual(self.OUTPUT,
                         "(stdin):10: Variable 'a' already declared at (stdin):10\n")

    def test_declare_variable_dupl_suffix(self):
        # Declares 'a' (integer) variable
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        # Checks for duplicated var name using suffixes
        self.s.declare_variable('a%', 11, self.btyperef(TYPE.integer))
        self.assertEqual(self.OUTPUT,
                         "(stdin):11: Variable 'a%' already declared at (stdin):10\n")

    def test_declare_variable_wrong_suffix(self):
        self.s.declare_variable('b%', 12, self.btyperef(TYPE.byte_))
        self.assertEqual(self.OUTPUT,
                         "(stdin):12: 'b%' suffix is for type 'integer' but it was declared as 'byte'\n")

    def test_declare_variable_remove_suffix(self):
        # Ensures suffix is removed
        self.s.declare_variable('c%', 12, self.btyperef(TYPE.integer))
        self.assertFalse(self.s.get_entry('c').name[-1] in DEPRECATED_SUFFIXES)

    def test_declare_param_dupl(self):
        # Declares 'a' (integer) variable
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        # Now declares 'a' (integer) parameter
        p = self.s.declare_param('a', 11, self.btyperef(TYPE.integer))
        self.assertIsNone(p)
        self.assertEqual(self.OUTPUT, '(stdin):11: Duplicated parameter "a" (previous one at (stdin):10)\n')

    def test_declare_param(self):
        # Declares 'a' (integer) parameter
        p = self.s.declare_param('a', 11, self.btyperef(TYPE.integer))
        self.assertIsInstance(p, symbols.PARAMDECL)
        self.assertEqual(p.scope, SCOPE.parameter)
        self.assertEqual(p.class_, CLASS.var)
        self.assertNotEqual(p.t[0], '$')

    def test_declare_param_str(self):
        # Declares 'a' (integer) parameter
        p = self.s.declare_param('a', 11, self.btyperef(TYPE.string))
        self.assertIsInstance(p, symbols.PARAMDECL)
        self.assertEqual(p.scope, SCOPE.parameter)
        self.assertEqual(p.class_, CLASS.var)
        self.assertEqual(p.t[0], '$')

    def test_get_entry(self):
        s = SymbolTable()
        var_a = s.get_entry('a')
        self.assertIsNone(var_a)
        s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        var_a = s.get_entry('a')
        self.assertIsNotNone(var_a)
        self.assertIsInstance(var_a, symbols.VAR)
        self.assertEqual(var_a.scope, SCOPE.global_)

    def test_enter_scope(self):
        # Declares a variable named 'a'
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        self.s.enter_scope('testfunction')
        self.assertNotEqual(self.s.current_scope, self.s.global_scope)
        self.assertTrue(self.s.check_is_undeclared('a', 11, scope=self.s.current_scope))

    def test_declare_local_var(self):
        self.s.enter_scope('testfunction')
        self.s.declare_variable('a', 12, self.btyperef(TYPE.float_))
        self.assertTrue(self.s.check_is_declared('a', 11, scope=self.s.current_scope))
        self.assertEqual(self.s.get_entry('a').scope, SCOPE.local)

    def test_declare_array(self):
        self.s.declare_array('test', lineno=1, type_=self.btyperef(TYPE.byte_), bounds=self.bounds)

    def test_declare_array_fail(self):
        # type_ must by an instance of symbols.TYPEREF
        self.assertRaises(AssertionError, self.s.declare_array, 'test', 1, TYPE.byte_, self.bounds)

    def test_declare_array_fail2(self):
        # bounds must by an instance of symbols.BOUNDLIST
        self.assertRaises(AssertionError, self.s.declare_array, 'test', 1, self.btyperef(TYPE.byte_),
                          'bla')

    def test_declare_local_array(self):
        ''' the logic for declaring a local array differs from
        local scalar variables
        '''
        self.s.enter_scope('testfunction')
        self.s.declare_array('a', 12, self.btyperef(TYPE.float_),
                             symbols.BOUNDLIST(symbols.BOUND(0, 2)))
        self.assertTrue(self.s.check_is_declared('a', 11, scope=self.s.current_scope))
        self.assertEqual(self.s.get_entry('a').scope, SCOPE.local)

    def test_declare_local_var_dup(self):
        self.s.enter_scope('testfunction')
        self.s.declare_variable('a', 12, self.btyperef(TYPE.float_))
        # Now checks for duplicated name 'a'
        self.s.declare_variable('a', 14, self.btyperef(TYPE.float_))
        self.assertEqual(self.OUTPUT,
                        "(stdin):14: Variable 'a' already declared at (stdin):12\n")

    def test_leave_scope(self):
        self.s.enter_scope('testfunction')
        # Declares a variable named 'a'
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        self.s.leave_scope()
        self.assertEqual(self.s.current_scope, self.s.global_scope)

    def test_local_var_cleaned(self):
        self.s.enter_scope('testfunction')
        # Declares a variable named 'a'
        self.s.declare_variable('a', 10, self.btyperef(TYPE.integer))
        self.s.leave_scope()
        self.assertTrue(self.s.check_is_undeclared('a', 10))

    def btyperef(self, type_):
        assert TYPE.is_valid(type_)
        return symbols.TYPEREF(symbols.BASICTYPE(type_), 0)

    def clearOutput(self):
        OPTIONS.remove_option('stderr')
        OPTIONS.add_option('stderr', default_value=StringIO())

    @property
    def OUTPUT(self):
        return OPTIONS.stderr.value.getvalue()


if __name__ == '__main__':
    unittest.main()
