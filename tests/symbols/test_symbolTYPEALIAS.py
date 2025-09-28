# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

from src.api.constants import TYPE
from src.symbols.type_ import SymbolBASICTYPE, SymbolTYPEALIAS


class TestSymbolTYPEALIAS(TestCase):
    def test__eq__(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            ta = SymbolTYPEALIAS("alias", 0, t)
            self.assertEqual(t.size, ta.size)
            self.assertTrue(ta == ta)
            self.assertTrue(t == ta)
            self.assertTrue(ta == t)

    def test_is_alias(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            ta = SymbolTYPEALIAS("alias", 0, t)
            self.assertTrue(ta.is_alias)
            self.assertTrue(ta.is_basic)
            self.assertFalse(t.is_alias)
