# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

from src.api.constants import TYPE
from src.symbols.type_ import SymbolBASICTYPE, SymbolTYPE, SymbolTYPEREF, Type


class TestSymbolTYPE(TestCase):
    def test__eq__(self):
        for t1_ in TYPE.types:
            t = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                if t1_ == t2_:
                    continue

                tt = SymbolBASICTYPE(t2_)
                self.assertTrue(t == t)
                self.assertFalse(t != t)
                self.assertFalse(tt == t)
                self.assertFalse(t == tt)
                self.assertTrue(tt == tt)
                self.assertFalse(tt != tt)
                self.assertTrue(t != tt)
                self.assertTrue(tt != t)

    def test_is_basic(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                t = SymbolTYPE("test_type", 0, t1, t2)
                self.assertFalse(t.is_basic)

    def test_is_alias(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                t = SymbolTYPE("test_type", 0, t1, t2)
                self.assertFalse(t.is_alias)

    def test_size(self):
        for t1_ in TYPE.types:
            t = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                tt = SymbolBASICTYPE(t2_)
                self.assertEqual(TYPE.size(t1_) + TYPE.size(t2_), t.size + tt.size)

    def test_cmp_types(self):
        """Test == operator for different types"""
        tr = SymbolTYPEREF(Type.unknown, 0)
        self.assertTrue(tr == Type.unknown)
        self.assertRaises(NotImplementedError, tr.__eq__, "dummy")
