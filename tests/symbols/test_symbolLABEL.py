# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

__author__ = "boriel"

from unittest import TestCase

from src.api import global_
from src.symbols.id_ import SymbolID


class TestSymbolLABEL(TestCase):
    def setUp(self):
        self.label_name = "test"
        self.l = SymbolID(self.label_name, 1).to_label()

    def test_t(self):
        self.assertEqual(self.l.t, f"{global_.LABELS_NAMESPACE}.{global_.MANGLE_CHR}{self.label_name}")

    def test_accessed(self):
        self.assertFalse(self.l.accessed)

    def test_scope_owner(self):
        self.assertEqual(self.l.scope_owner, [])

    def test_scope_owner_set(self):
        tmp = SymbolID("another", 2).to_label()
        self.l.ref.scope_owner = [tmp]
        self.assertEqual(self.l.scope_owner, [tmp])

    def test_set_accessed(self):
        tmp = SymbolID("another", 2).to_label()
        self.l.ref.scope_owner = [tmp]
        self.l.accessed = True
        self.assertTrue(self.l.accessed)
        self.assertTrue(tmp.accessed)
