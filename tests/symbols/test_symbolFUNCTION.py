#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__

import symbols
from api.constants import CLASS


class TestSymbolFUNCTION(TestCase):
    def setUp(self):
        self.fname = 'test'
        self.f = symbols.FUNCTION(self.fname, 1)

    def test__init__(self):
        self.assertTrue(self.f.callable)
        self.assertEqual(self.f.class_, CLASS.function)
        self.assertEqual(self.fname, self.f.name)
        self.assertEqual(self.f.mangled, '_%s' % self.f.name)

    '''
    def test_fromVAR(self):
        f = symbols.FUNCTION.fromVAR(symbols.VAR(self.f.name, lineno=2))
        self.assertEqual(f.name, self.f.name)
        self.assertTrue(f.callable)
        self.assertEqual(f.mangled, self.f.mangled)
        self.assertEqual(f.class_, CLASS.function)
    '''

    def test_params_getter(self):
        self.assertIsInstance(self.f.params, symbols.PARAMLIST)
        self.assertEqual(len(self.f.params), 0)

    def test_params_setter(self):
        params = symbols.PARAMLIST()
        self.f.params = params
        self.assertEqual(self.f.params, params)

    def test_body_getter(self):
        self.assertIsInstance(self.f.body, symbols.BLOCK)
        self.assertEqual(len(self.f.body), 0)

    def test_body_setter(self):
        body = symbols.BLOCK(symbols.NUMBER(0, lineno=1))
        self.f.body = body
        self.assertEqual(len(self.f.body), len(body))
        self.assertEqual(self.f.body, body)


if __name__ == '__main__':
    unittest.main()
