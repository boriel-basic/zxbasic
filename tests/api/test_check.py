#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest

from src.api import check
from src import symbols


class TestCheck(unittest.TestCase):
    """Tests api.check"""

    def test_is_temporary_value_const_string(self):
        node = symbols.STRING("Hello world", 1)
        self.assertFalse(check.is_temporary_value(node))

    def test_is_temporary_value_var(self):
        node = symbols.VAR("a", 1)
        self.assertFalse(check.is_temporary_value(node))

    def test_is_temporary_value_param(self):
        node = symbols.PARAMDECL("a", 1)
        self.assertFalse(check.is_temporary_value(node))

    def test_is_temporary_value_expr(self):
        child = symbols.VAR("a", 1)
        node = symbols.BINARY("PLUS", child, child, 1)
        self.assertTrue(check.is_temporary_value(node))
