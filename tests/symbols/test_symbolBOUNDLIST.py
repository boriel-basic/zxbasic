#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
from unittest import TestCase

# Initialize import syspath
import __init__

import symbols

class TestSymbolBOUNDLIST(TestCase):
    def test_make_node(self):
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = symbols.BOUND(l1, l2)
        c = symbols.BOUND(l3, l4)
        a = symbols.BOUNDLIST.make_node(None, b, c)

    def test__str__(self):
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = symbols.BOUND(l1, l2)
        c = symbols.BOUND(l3, l4)
        a = symbols.BOUNDLIST.make_node(None, b, c)
        self.assertEqual(str(a), '(({} TO {}), ({} TO {}))'.format(l1, l2, l3, l4))

    def test__len__(self):
        l1 = 1
        l2 = 2
        l3 = 3
        l4 = 4
        b = symbols.BOUND(l1, l2)
        c = symbols.BOUND(l3, l4)
        a = symbols.BOUNDLIST(b, c)
        self.assertEqual(len(a), 2)

if __name__ == '__main__':
    unittest.main()
