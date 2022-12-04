#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
from io import StringIO
from unittest import TestCase

import src.api.global_ as gl_
from src.api.config import OPTION, OPTIONS, Action
from src.api.constants import CLASS, DEPRECATED_SUFFIXES, SCOPE, TYPE
from src.api.symboltable.symboltable import SymbolTable
from src.symbols import sym


class TestSymbolTable(TestCase):
    def setUp(self):
        self.clearOutput()
        self.s = gl_.SYMBOL_TABLE = SymbolTable()
        l1, l2, l3, l4 = 1, 2, 3, 4
        b = sym.BOUND(l1, l2)
        c = sym.BOUND(l3, l4)
        self.bounds = sym.BOUNDLIST.make_node(None, b, c)
        self.func = sym.FUNCDECL.make_node("testfunction", 1, class_=CLASS.function)

    def test__init__(self):
        """Tests symbol table initialization"""
        OPTIONS[OPTION.O_LEVEL].push()
        OPTIONS.optimization_level = 0
        self.assertEqual(len(self.s.types), len(TYPE.types))
        for type_ in self.s.types:
            self.assertTrue(type_.is_basic)
            self.assertIsInstance(type_, sym.BASICTYPE)

        self.assertEqual(self.s.current_scope, self.s.global_scope)
        OPTIONS[OPTION.O_LEVEL].pop()

    def test_is_declared(self):
        # Checks variable 'a' is not declared yet
        self.assertFalse(self.s.check_is_declared("a", 0, "var", show_error=False))
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        # Checks variable 'a' is declared
        self.assertTrue(self.s.check_is_declared("a", 1, "var", show_error=False))

    def test_is_undeclared(self):
        s = SymbolTable()
        # Checks variable 'a' is undeclared
        self.assertTrue(s.check_is_undeclared("a", 10, show_error=False))
        s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        # Checks variable 'a' is not undeclared
        self.assertFalse(s.check_is_undeclared("a", 10, show_error=False))

    def test_declare_variable(self):
        # Declares 'a' (integer) variable
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        self.assertIsNotNone(self.s.current_scope["a"])

    def test_declare_variable_dupl(self):
        # Declares 'a' (integer) variable
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        # Now checks for duplicated name 'a'
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        self.assertEqual(self.OUTPUT, "(stdin):10: error: Variable 'a' already declared at (stdin):10\n")

    def test_declare_variable_dupl_suffix(self):
        # Declares 'a' (integer) variable
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        # Checks for duplicated var name using suffixes
        self.s.declare_variable("a%", 11, self.btyperef(TYPE.integer))
        self.assertEqual(self.OUTPUT, "(stdin):11: error: Variable 'a%' already declared at (stdin):10\n")

    def test_declare_variable_wrong_suffix(self):
        self.s.declare_variable("b%", 12, self.btyperef(TYPE.byte))
        self.assertEqual(
            self.OUTPUT,
            (
                "(stdin):12: error: expected type integer for 'b%', got byte\n"
                "(stdin):12: error: 'b%' suffix is for type 'integer' but it was declared as 'byte'\n"
            ),
        )

    def test_declare_variable_remove_suffix(self):
        # Ensures suffix is removed
        self.s.declare_variable("c%", 12, self.btyperef(TYPE.integer))
        self.assertFalse(self.s.get_entry("c").name[-1] in DEPRECATED_SUFFIXES)

    def test_declare_param_dupl(self):
        # Declares 'a' (integer) variable
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        # Now declares 'a' (integer) parameter
        p = self.s.declare_param("a", 11, self.btyperef(TYPE.integer))
        self.assertIsNone(p)
        self.assertEqual(self.OUTPUT, '(stdin):11: error: Duplicated parameter "a" (previous one at (stdin):10)\n')

    def test_declare_param(self):
        # Declares 'a' (integer) parameter
        p = self.s.declare_param("a", 11, self.btyperef(TYPE.integer))
        self.assertIsInstance(p, sym.ID)
        self.assertEqual(p.scope, SCOPE.parameter)
        self.assertEqual(p.class_, CLASS.var)
        self.assertNotEqual(p.t[0], "$")

    def test_declare_param_str(self):
        # Declares 'a' (integer) parameter
        p = self.s.declare_param("a", 11, self.btyperef(TYPE.string))
        self.assertIsInstance(p, sym.ID)
        self.assertEqual(p.scope, SCOPE.parameter)
        self.assertEqual(p.class_, CLASS.var)
        self.assertEqual(p.t[0], "$")

    def test_get_entry(self):
        s = SymbolTable()
        var_a = s.get_entry("a")
        self.assertIsNone(var_a)
        s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        var_a = s.get_entry("a")
        self.assertIsNotNone(var_a)
        self.assertIsInstance(var_a, sym.ID)
        self.assertEqual(var_a.class_, CLASS.var)
        self.assertEqual(var_a.scope, SCOPE.global_)

    def test_enter_scope(self):
        # Declares a variable named 'a'
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        self.s.enter_scope("testfunction")
        self.assertNotEqual(self.s.current_scope, self.s.global_scope)
        self.assertTrue(self.s.check_is_undeclared("a", 11, scope=self.s.current_scope))

    def test_declare_local_var(self):
        self.s.enter_scope("testfunction")
        self.s.declare_variable("a", 12, self.btyperef(TYPE.float))
        self.assertTrue(self.s.check_is_declared("a", 11, scope=self.s.current_scope))
        self.assertEqual(self.s.get_entry("a").scope, SCOPE.local)

    def test_declare_array(self):
        self.s.declare_array("test", lineno=1, type_=self.btyperef(TYPE.byte), bounds=self.bounds)

    def test_declare_array_fail(self):
        # type_ must by an instance of sym.TYPEREF
        self.assertRaises(AssertionError, self.s.declare_array, "test", 1, TYPE.byte, self.bounds)

    def test_declare_array_fail2(self):
        # bounds must by an instance of sym.BOUNDLIST
        self.assertRaises(AssertionError, self.s.declare_array, "test", 1, self.btyperef(TYPE.byte), "bla")

    def test_declare_local_array(self):
        """the logic for declaring a local array differs from
        local scalar variables
        """
        self.s.enter_scope("testfunction")
        self.s.declare_array("a", 12, self.btyperef(TYPE.float), sym.BOUNDLIST(sym.BOUND(0, 2)))
        self.assertTrue(self.s.check_is_declared("a", 11, scope=self.s.current_scope))
        self.assertEqual(self.s.get_entry("a").scope, SCOPE.local)

    def test_declare_local_var_dup(self):
        self.s.enter_scope("testfunction")
        self.s.declare_variable("a", 12, self.btyperef(TYPE.float))
        # Now checks for duplicated name 'a'
        self.s.declare_variable("a", 14, self.btyperef(TYPE.float))
        self.assertEqual(self.OUTPUT, "(stdin):14: error: Variable 'a' already declared at (stdin):12\n")

    def test_leave_scope(self):
        self.s.enter_scope("testfunction")
        # Declares a variable named 'a'
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        self.s.leave_scope()
        self.assertEqual(self.s.current_scope, self.s.global_scope)

    def test_local_var_cleaned(self):
        self.s.enter_scope("testfunction")
        # Declares a variable named 'a'
        self.s.declare_variable("a", 10, self.btyperef(TYPE.integer))
        self.s.leave_scope()
        self.assertTrue(self.s.check_is_undeclared("a", 10))

    def btyperef(self, type_):
        assert TYPE.is_valid(type_)
        return sym.TYPEREF(sym.BASICTYPE(type_), 0)

    def clearOutput(self):
        del OPTIONS.stderr
        OPTIONS(Action.ADD, name="stderr", default=StringIO())

    @property
    def OUTPUT(self):
        return OPTIONS.stderr.getvalue()


if __name__ == "__main__":
    unittest.main()
