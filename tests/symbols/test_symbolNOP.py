# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

from src.symbols.sym import NOP

__author__ = "boriel"


class TestSymbolBLOCK(TestCase):
    def setUp(self):
        self.nop = NOP()

    def test__len_0(self):
        self.assertEqual(len(self.nop), 0, "NOP must have 0 length")

    def test__assert_false(self):
        self.assertFalse(self.nop)
