#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

from src.api.constants import CLASS
from src.symbols import sym


class TestSymbolFUNCTION(TestCase):
    def setUp(self):
        self.fname = "test"
        self.f = sym.ID(self.fname, 1).to_function(class_=CLASS.function)

    def test__init__(self):
        self.assertTrue(self.f.callable)
        self.assertEqual(self.f.class_, CLASS.function)
        self.assertEqual(self.fname, self.f.name)
        self.assertEqual(self.f.mangled, "_%s" % self.f.name)

    """
    def test_fromVAR(self):
        f = sym.FUNCTION.fromVAR(sym.VAR(self.f.name, lineno=2))
        self.assertEqual(f.name, self.f.name)
        self.assertTrue(f.callable)
        self.assertEqual(f.mangled, self.f.mangled)
        self.assertEqual(f.class_, CLASS.function)
    """

    def test_params_getter(self):
        self.assertIsInstance(self.f.params, sym.PARAMLIST)
        self.assertEqual(len(self.f.params), 0)

    def test_params_setter(self):
        params = sym.PARAMLIST()
        self.f.ref.params = params
        self.assertEqual(self.f.params, params)

    def test_body_getter(self):
        self.assertIsInstance(self.f.body, sym.BLOCK)
        self.assertEqual(len(self.f.body), 0)

    def test_body_setter(self):
        body = sym.BLOCK(sym.NUMBER(0, lineno=1))
        self.f.ref.body = body
        self.assertEqual(len(self.f.body), len(body))
        self.assertEqual(self.f.body, body)


if __name__ == "__main__":
    unittest.main()
