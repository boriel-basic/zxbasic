# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from io import StringIO
from unittest import TestCase

from src.api.config import OPTIONS, Action
from src.symbols import sym
from src.zxbpp import zxbpp


class TestSymbolBOUND(TestCase):
    def setUp(self):
        zxbpp.init()

    def test__init__(self):
        self.assertRaises(AssertionError, sym.BOUND, "a", 3)
        self.assertRaises(AssertionError, sym.BOUND, 1, "a")
        self.assertRaises(AssertionError, sym.BOUND, 3, 1)

    def test_count(self):
        lower = 1
        upper = 3
        b = sym.BOUND(lower, upper)
        self.assertEqual(b.count, upper - lower + 1)

    def test_make_node(self):
        self.clearOutput()
        l = sym.NUMBER(2, lineno=1)
        u = sym.NUMBER(3, lineno=2)
        sym.BOUND.make_node(l, u, 3)
        self.assertEqual(self.stderr, "")

        l = sym.NUMBER(4, lineno=1)
        sym.BOUND.make_node(l, u, 3)
        self.assertEqual(self.stderr, "(stdin):3: error: Lower array bound must be less or equal to upper one\n")

        self.clearOutput()
        l = sym.NUMBER(-4, lineno=1)
        sym.BOUND.make_node(l, u, 3)
        self.assertEqual(self.stderr, "(stdin):3: error: Array bounds must be greater than 0\n")

        self.clearOutput()
        l = sym.ID("a", 10).to_var()
        sym.BOUND.make_node(l, u, 3)
        self.assertEqual(self.stderr, "(stdin):3: error: Array bounds must be constants\n")

    def test__str__(self):
        b = sym.BOUND(1, 3)
        self.assertEqual(str(b), "(1 TO 3)")

    def test__repr__(self):
        b = sym.BOUND(1, 3)
        self.assertEqual(b.__repr__(), b.token + "(1 TO 3)")

    def clearOutput(self):
        del OPTIONS.stderr
        OPTIONS(Action.ADD, name="stderr", default=StringIO())

    @property
    def stderr(self):
        return OPTIONS.stderr.getvalue()
