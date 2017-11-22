#!/usr/bin/env python
# -*- coding: utf-8 -*-

from unittest import TestCase
from symbols import NOP


__author__ = 'boriel'


class TestSymbolBLOCK(TestCase):
    def setUp(self):
        self.nop = NOP()

    def test__len_0(self):
        self.assertEqual(len(self.nop), 0, "NOP must have 0 length")

    def test__assert_false(self):
        self.assertFalse(self.nop)
