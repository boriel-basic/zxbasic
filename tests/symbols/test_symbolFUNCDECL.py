#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase
from StringIO import StringIO

# Initialize import syspath
import __init__

from symbols import FUNCDECL


class TestSymbolFUNCDECL(TestCase):
    def test__init__(self):
        s = FUNCDECL()

    def test_name(self):
        self.fail()

    def test_locals_size(self):
        self.fail()

    def test_locals_size(self):
        self.fail()

    def test_local_symbol_table(self):
        self.fail()

    def test_local_symbol_table(self):
        self.fail()

    def test_type_(self):
        self.fail()

    def test_type_(self):
        self.fail()

    def test_size(self):
        self.fail()

    def test_mangled_(self):
        self.fail()

    def test_make_node(self):
        f = FUNCDECL.make_node('f', 1)
        self.assertIsNotNone(f)


if __name__ == '__main__':
    unittest.main()
