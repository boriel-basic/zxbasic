#!/usr/bin/env python
# -*- coding: utf-8 -*-

from unittest import TestCase

# Initialize import syspath
import __init__

import api.global_ as gl
from api.constants import TYPE
from api.constants import CLASS
from symbols.type_ import Type
import symbols
import functools


class TestSymbolVARARRAY(TestCase):
    def setUp(self):
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = symbols.BOUND(l1, l2)
        c = symbols.BOUND(l3, l4)
        self.bounds = symbols.BOUNDLIST.make_node(None, b, c)

    def test__init__fail(self):
        self.assertRaises(AssertionError, symbols.VARARRAY, 'test', 'blahblah', 2)

    def test__init__(self):
        arr = symbols.VARARRAY('test', self.bounds, 1, type_=Type.ubyte)
        self.assertEqual(arr.class_, CLASS.array)
        self.assertEqual(arr.type_, Type.ubyte)

    def test_bounds(self):
        arr = symbols.VARARRAY('test', self.bounds, 1)
        self.assertEqual(arr.bounds, self.bounds)

    def test_count(self):
        arr = symbols.VARARRAY('test', self.bounds, 1)
        self.assertEqual(arr.count, functools.reduce(lambda x, y: x * y, (x.count for x in self.bounds)))

    def test_size(self):
        arr = symbols.VARARRAY('test', self.bounds, 1, type_=Type.ubyte)
        self.assertEqual(arr.size, arr.type_.size * arr.count)

    def test_memsize(self):
        arr = symbols.VARARRAY('test', self.bounds, 1, type_=Type.ubyte)
        self.assertEqual(arr.memsize, arr.size + 1 + TYPE.size(gl.BOUND_TYPE) * len(arr.bounds))
