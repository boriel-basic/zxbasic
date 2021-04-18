#!/usr/bin/env python
# -*- coding: utf-8 -*-

from unittest import TestCase
from io import StringIO

from src import symbols
import src.api.global_ as gl
import src.api.config as config
from src.api.symboltable import SymbolTable
from src.symbols.type_ import Type
from src.zxbpp import zxbpp


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
        config.OPTIONS(config.Action.ADD, name='stderr', default=StringIO())
        config.OPTIONS(config.Action.ADD_IF_NOT_DEFINED, name='explicit', type=bool, default=False)

        self.aa1 = symbols.ARRAYACCESS(self.arr, self.arg, 2, 'fake-filename')

    @property
    def OUTPUT(self):
        return config.OPTIONS.stderr.getvalue()

    def test__init__(self):
        self.assertIsInstance(self.aa1, symbols.ARRAYACCESS)

    def test__init__fail(self):
        # First argument must be an instance of VARARRAY
        self.assertRaises(AssertionError, symbols.ARRAYACCESS, 'bla', self.arg, 2, 'fake-filename')

    def test_entry__getter(self):
        self.assertIs(self.aa1.entry, self.arr)

    def test_entry__setter(self):
        ar2 = symbols.VARARRAY('test2', self.bounds, 1, type_=Type.ubyte)
        self.aa1.entry = ar2
        self.assertIs(self.aa1.entry, ar2)

    def test_entry__setter_fail(self):
        # entry must be an instance of VARARRAY
        self.assertRaises(AssertionError, symbols.ARRAYACCESS.entry.fset, self.aa1, 'blah')

    def test_scope(self):
        self.assertEqual(self.aa1.scope, self.arr.scope)

    def test_make_node(self):
        gl.SYMBOL_TABLE.declare_array('test', 1, symbols.TYPEREF(self.arr.type_, 1),
                                      bounds=self.bounds)
        self.aa2 = symbols.ARRAYACCESS.make_node('test', self.arg, lineno=2, filename='fake-filename')
        self.assertIsInstance(self.aa2, symbols.ARRAYACCESS)

    def test_make_node_fail(self):
        gl.SYMBOL_TABLE.declare_array('test', 1, symbols.TYPEREF(self.arr.type_, 1),
                                      bounds=self.bounds)
        self.arg = symbols.ARGLIST(symbols.ARGUMENT(symbols.NUMBER(2, 1), 1))
        self.aa2 = symbols.ARRAYACCESS.make_node('test', self.arg, lineno=2, filename='fake-filename')
        self.assertIsNone(self.aa2)
        self.assertEqual(self.OUTPUT, "(stdin):2: error: Array 'test' has 2 dimensions, not 1\n")

    def test_make_node_warn(self):
        gl.SYMBOL_TABLE.declare_array('test', 1, symbols.TYPEREF(self.arr.type_, 1),
                                      bounds=self.bounds)
        self.arg[1] = symbols.ARGUMENT(symbols.NUMBER(9, 1), 1)
        self.aa2 = symbols.ARRAYACCESS.make_node('test', self.arg, lineno=2, filename='fake-filename')
        self.assertIsNotNone(self.aa2)
        self.assertEqual(self.OUTPUT, "(stdin):2: warning: Array 'test' subscript out of range\n")

    def test_offset(self):
        gl.SYMBOL_TABLE.declare_array('test', 1, symbols.TYPEREF(self.arr.type_, 1),
                                      bounds=self.bounds)
        self.aa2 = symbols.ARRAYACCESS.make_node('test', self.arg, lineno=2, filename='fake-filename')
        self.assertIsInstance(self.aa2, symbols.ARRAYACCESS)
        self.assertIsNotNone(self.aa2.offset)
        self.assertEqual(self.aa2.offset, 2)
