#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__

import symbols
from api.constants import CLASS
from api.constants import TYPE

class TestSymbolFUNCTION(TestCase):
    def test__init__(self):
        f = symbols.FUNCTION('test', 1)
        self.assertTrue(f.callable)
        self.assertEqual(f.class_, CLASS.function)
        self.assertEqual(f.mangled, '_%s' % f.name)







if __name__ == '__main__':
    unittest.main()
