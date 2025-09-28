# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

import src.api.global_ as gl
import src.api.symboltable
import src.api.symboltable.symboltable
from src.api.constants import CLASS
from src.symbols.sym import FUNCDECL
from src.symbols.type_ import Type


class TestSymbolFUNCDECL(TestCase):
    def setUp(self):
        src.api.global_.SYMBOL_TABLE = src.api.symboltable.symboltable.SymbolTable()
        self.f = gl.SYMBOL_TABLE.declare_func("f", 1, type_=Type.ubyte)
        self.s = FUNCDECL(self.f, 1)

    def test__init__fail(self):
        self.assertRaises(AssertionError, FUNCDECL, "bla", 1)

    def test_entry__getter(self):
        self.assertEqual(self.s.entry, self.f)

    def test_entry__setter(self):
        self.s.entry = tmp = gl.SYMBOL_TABLE.declare_func("q", 1)
        self.assertEqual(self.s.entry, tmp)

    def test_entry_fail__(self):
        self.assertRaises(AssertionError, FUNCDECL.entry.fset, self.s, "blah")

    def test_name(self):
        self.assertEqual(self.s.name, "f")

    def test_locals_size(self):
        self.assertEqual(self.s.locals_size, 0)

    def test_local_symbol_table(self):
        self.assertIsNone(self.s.local_symbol_table)

    def test_local_symbol_table__setter_fail(self):
        self.assertRaises(AssertionError, FUNCDECL.local_symbol_table.fset, self.s, "blah")

    def test_type_(self):
        self.assertEqual(self.s.type_, Type.ubyte)

    def test_size(self):
        self.assertEqual(self.s.type_.size, Type.ubyte.size)

    def test_mangled_(self):
        self.assertEqual(self.s.mangled, "_f")

    def test_make_node(self):
        f = FUNCDECL.make_node("f", 1, class_=CLASS.function)
        self.assertIsNotNone(f)
