# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

from src.api.constants import TYPE
from src.symbols.type_ import SymbolBASICTYPE, SymbolTYPE, SymbolTYPEREF, Type


class TestSymbolTYPE(TestCase):
    def test__eq__(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                t = SymbolTYPE("test_type", 0, t1, t2)
                tt = SymbolTYPE("other_type", 0, t)
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
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                t = SymbolTYPE("test_type", 0, t1, t2)
                self.assertEqual(t.size, t1.size + t2.size)

    def test_cmp_types(self):
        """Test == operator for different types"""
        tr = SymbolTYPEREF(Type.unknown, 0)
        self.assertTrue(tr == Type.unknown)
        self.assertRaises(AssertionError, tr.__eq__, TYPE.unknown)
