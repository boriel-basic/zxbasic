# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from unittest import TestCase

from src.symbols import sym
from src.symbols.type_ import Type


class TestSymbolSTRING(TestCase):
    def test__init__(self):
        self.assertRaises(AssertionError, sym.STRING, 0, 1)
        _zxbasic = "zxbasic"
        _ZXBASIC = "ZXBASIC"
        s = sym.STRING(_zxbasic, 1)
        t = sym.STRING(_ZXBASIC, 2)
        self.assertEqual(s, s)
        self.assertNotEqual(s, t)
        self.assertEqual(s, _zxbasic)
        self.assertEqual(_ZXBASIC, t)
        self.assertGreater(s, t)
        self.assertLess(t, s)
        self.assertGreaterEqual(s, t)
        self.assertLessEqual(t, s)
        self.assertEqual(s.type_, Type.string)
        self.assertEqual(str(s), _zxbasic)
        self.assertEqual(f'"{_zxbasic}"', s.__repr__())
        self.assertEqual(s.t, _zxbasic)
        s.t = _ZXBASIC
        self.assertEqual(s.t, _ZXBASIC)
        self.assertRaises(AssertionError, sym.STRING.t.fset, s, 0)
        self.assertEqual(s.value, _zxbasic)
