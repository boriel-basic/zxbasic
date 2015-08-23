# -*- coding: utf-8 -*-

__author__ = 'boriel'

from unittest import TestCase
from symbols import LABEL


class TestSymbolLABEL(TestCase):
    def setUp(self):
        self.label_name = 'test'
        self.l = LABEL(self.label_name, 1)

    def test_t(self):
        self.assertEqual(self.l.t, LABEL.prefix + self.label_name)

    def test_accessed(self):
        self.assertFalse(self.l.accessed)

    def test_scope_owner(self):
        self.assertEqual(self.l.scope_owner, list())

    def test_scope_owner_set(self):
        tmp = LABEL('another', 2)
        self.l.scope_owner = [tmp]
        self.assertEqual(self.l.scope_owner, [tmp])

    def test_set_accessed(self):
        tmp = LABEL('another', 2)
        self.l.scope_owner = [tmp]
        self.l.accessed = True
        self.assertTrue(self.l.accessed)
        self.assertTrue(tmp.accessed)
