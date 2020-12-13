#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest

from src.api import utils


class TestUtils(unittest.TestCase):
    """ Tests api.config initialization
    """
    def test_parse_int_empty_is_None(self):
        self.assertIsNone(utils.parse_int(None))
        self.assertIsNone(utils.parse_int(''))
        self.assertIsNone(utils.parse_int('  \t '))

    def test_parse_int_float_is_None(self):
        self.assertIsNone(utils.parse_int('3.5'))

    def test_parse_int_decimal(self):
        self.assertEqual(utils.parse_int('  0 '), 0)
        self.assertEqual(utils.parse_int('1'), 1)

    def test_parse_int_hexadecimal(self):
        self.assertEqual(utils.parse_int('  0xFF'), 0xFF)
        self.assertEqual(utils.parse_int('  0xFFh'), None)
        self.assertEqual(utils.parse_int(' $FF'), 255)
        self.assertEqual(utils.parse_int('FFh'), None)  # could be a label
        self.assertEqual(utils.parse_int('0FFh'), 255)
        self.assertEqual(utils.parse_int('111b'), 7)
        self.assertEqual(utils.parse_int('%111'), 7)
