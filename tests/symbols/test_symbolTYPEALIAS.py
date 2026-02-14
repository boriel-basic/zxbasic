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
            ta = SymbolTYPEALIAS("alias", "", alias=t, lineno=0)
            self.assertEqual(t.size, ta.size)
            self.assertTrue(ta == ta)
            self.assertTrue(t.final == ta.final)
            self.assertTrue(ta.final == t.final)

    def test_is_alias(self):
        for type_ in TYPE.types:
            t = SymbolBASICTYPE(type_)
            ta = SymbolTYPEALIAS("alias", "", alias=t, lineno=0)
            self.assertTrue(ta.is_alias)
            self.assertTrue(ta.is_basic)
            self.assertFalse(t.is_alias)
