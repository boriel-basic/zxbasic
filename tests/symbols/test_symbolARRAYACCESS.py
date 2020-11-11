#!/usr/bin/env python
# -*- coding: utf-8 -*-

from unittest import TestCase
from six import StringIO

from src import symbols
import src.api.global_ as gl
import src.api.config as config
from src.api.symboltable import SymbolTable
from src.symbols.type_ import Type
from src.libzxbpp import zxbpp


class TestSymbolARRAYACCESS(TestCase):
    def setUp(self):
        zxbpp.init()
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = symbols.BOUND(l1, l2)
        c = symbols.BOUND(l3, l4)
        self.bounds = symbols.BOUNDLIST.make_node(None, b, c)
        self.arr = symbols.VARARRAY('test', self.bounds, 1, type_=Type.ubyte)
        self.arg = symbols.ARGLIST(symbols.ARGUMENT(symbols.NUMBER(2, 1, type_=Type.uinteger), 1),
                                   symbols.ARGUMENT(symbols.NUMBER(3, 1, type_=Type.uinteger), 1))
        gl.SYMBOL_TABLE = SymbolTable()
        # Clears stderr and prepares for capturing it
        del config.OPTIONS.stderr
        config.OPTIONS.add_option('stderr', None, StringIO())
        config.OPTIONS.add_option_if_not_defined('explicit', None, False)

    @property
    def OUTPUT(self):
        return config.OPTIONS.stderr.getvalue()

    def test__init__(self):
        aa = symbols.ARRAYACCESS(self.arr, self.arg, 2)
        self.assertIsInstance(aa, symbols.ARRAYACCESS)

    def test__init__fail(self):
        # First argument must be an instance of VARARRAY
        self.assertRaises(AssertionError, symbols.ARRAYACCESS, 'bla', self.arg, 2)

    def test_entry__getter(self):
        aa = symbols.ARRAYACCESS(self.arr, self.arg, 2)
        self.assertIs(aa.entry, self.arr)

    def test_entry__setter(self):
        aa = symbols.ARRAYACCESS(self.arr, self.arg, 2)
        ar2 = symbols.VARARRAY('test2', self.bounds, 1, type_=Type.ubyte)
        aa.entry = ar2
        self.assertIs(aa.entry, ar2)

    def test_entry__setter_fail(self):
        # entry must be an instance of VARARRAY
        aa = symbols.ARRAYACCESS(self.arr, self.arg, 2)
        self.assertRaises(AssertionError, symbols.ARRAYACCESS.entry.fset, aa, 'blah')

    def test_scope(self):
        aa = symbols.ARRAYACCESS(self.arr, self.arg, 2)
        self.assertEqual(aa.scope, self.arr.scope)

    def test_make_node(self):
        gl.SYMBOL_TABLE.declare_array('test', 1, symbols.TYPEREF(self.arr.type_, 1),
                                      bounds=self.bounds)
        aa = symbols.ARRAYACCESS.make_node('test', self.arg, lineno=2)
        self.assertIsInstance(aa, symbols.ARRAYACCESS)

    def test_make_node_fail(self):
        gl.SYMBOL_TABLE.declare_array('test', 1, symbols.TYPEREF(self.arr.type_, 1),
                                      bounds=self.bounds)
        self.arg = symbols.ARGLIST(symbols.ARGUMENT(symbols.NUMBER(2, 1), 1))
        aa = symbols.ARRAYACCESS.make_node('test', self.arg, lineno=2)
        self.assertIsNone(aa)
        self.assertEqual(self.OUTPUT, "(stdin):2: error: Array 'test' has 2 dimensions, not 1\n")

    def test_make_node_warn(self):
        gl.SYMBOL_TABLE.declare_array('test', 1, symbols.TYPEREF(self.arr.type_, 1),
                                      bounds=self.bounds)
        self.arg[1] = symbols.ARGUMENT(symbols.NUMBER(9, 1), 1)
        aa = symbols.ARRAYACCESS.make_node('test', self.arg, lineno=2)
        self.assertIsNotNone(aa)
        self.assertEqual(self.OUTPUT, "(stdin):2: warning: Array 'test' subscript out of range\n")

    def test_offset(self):
        gl.SYMBOL_TABLE.declare_array('test', 1, symbols.TYPEREF(self.arr.type_, 1),
                                      bounds=self.bounds)
        aa = symbols.ARRAYACCESS.make_node('test', self.arg, lineno=2)
        self.assertIsInstance(aa, symbols.ARRAYACCESS)
        self.assertIsNotNone(aa.offset)
        self.assertEqual(aa.offset, 2)
