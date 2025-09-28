# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

from src.api.constants import TYPE
from src.symbols.type_ import SymbolBASICTYPE, Type


class TestSymbolBASICTYPE(TestCase):
    def test_size(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            self.assertEqual(t.size, TYPE.size(type_))

    def test_is_basic(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            self.assertTrue(t.is_basic)

    def test_is_dynamic(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            self.assertTrue((type_ == TYPE.string) == t.is_dynamic)

    def test__eq__(self):
        for t_ in TYPE.types:
            t = SymbolBASICTYPE(t_)
            self.assertTrue(t == t)  # test same reference

        for t_ in TYPE.types:
            t1 = SymbolBASICTYPE(t_)
            t2 = SymbolBASICTYPE(t_)
            self.assertTrue(t1 == t2)

        t = SymbolBASICTYPE(TYPE.string)
        self.assertEqual(t, Type.string)

    def test__ne__(self):
        for t1_ in TYPE.types:
            t1 = SymbolBASICTYPE(t1_)
            for t2_ in TYPE.types:
                t2 = SymbolBASICTYPE(t2_)
                if t1 == t2:  # Already validated
                    self.assertTrue(t1 == t2)
                else:
                    self.assertTrue(t1 != t2)

    def test_to_signed(self):
        for type_ in TYPE.types:
            if type_ in {TYPE.unknown, TYPE.string, TYPE.boolean}:
                continue

            t = SymbolBASICTYPE(type_)
            q = t.to_signed()
            self.assertTrue(q.is_signed)

    def test_bool(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            if t.type_ == TYPE.unknown:
                self.assertFalse(t)
            else:
                self.assertTrue(t)
