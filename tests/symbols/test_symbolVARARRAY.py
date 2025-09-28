# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import functools
from unittest import TestCase

import src.api.global_ as gl
from src.api.constants import CLASS, TYPE
from src.symbols import sym
from src.symbols.type_ import Type


class TestSymbolVARARRAY(TestCase):
    def setUp(self):
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = sym.BOUND(l1, l2)
        c = sym.BOUND(l3, l4)
        self.bounds = sym.BOUNDLIST.make_node(None, b, c)
        self.arr = sym.ID("test", 1, type_=Type.ubyte).to_vararray(self.bounds)

    def test__init__fail(self):
        self.assertRaises(AssertionError, sym.ID("test", 2).to_vararray, "blahblah")

    def test__init__(self):
        self.assertEqual(self.arr.class_, CLASS.array)
        self.assertEqual(self.arr.type_, Type.ubyte)

    def test_bounds(self):
        self.assertEqual(self.arr.bounds, self.bounds)

    def test_count(self):
        self.assertEqual(self.arr.count, functools.reduce(lambda x, y: x * y, (x.count for x in self.bounds)))

    def test_size(self):
        self.assertEqual(self.arr.size, self.arr.type_.size * self.arr.count)

    def test_memsize(self):
        self.assertEqual(self.arr.memsize, 3 * TYPE.size(gl.PTR_TYPE))
