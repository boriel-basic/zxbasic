# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from io import StringIO
from unittest import TestCase

from src.api.config import OPTIONS, Action
from src.symbols import sym
from src.symbols.type_ import Type
from src.zxbpp import zxbpp


class TestSymbolBINARY(TestCase):
    def setUp(self):
        zxbpp.init()
        self.l = sym.ID("a", lineno=1, type_=Type.ubyte).to_var()
        self.r = sym.NUMBER(3, lineno=2)
        self.b = sym.BINARY("PLUS", self.l, self.r, lineno=3)
        self.st = sym.STRING("ZXBASIC", lineno=1)
        if "stderr" in OPTIONS:
            del OPTIONS.stderr
        OPTIONS(Action.ADD, name="stderr", default=StringIO())

    def test_left_getter(self):
        self.assertEqual(self.b.left, self.l)

    def test_left_setter(self):
        self.b.left = self.r
        self.assertEqual(self.b.left, self.r)

    def test_right_getter(self):
        self.assertEqual(self.b.right, self.r)

    def test_right_setter(self):
        self.b.right = self.l
        self.assertEqual(self.b.right, self.l)

    def test_size(self):
        self.assertEqual(self.b.size, self.b.type_.size)

    def test_make_node_None(self):
        """Makes a binary with 2 constants, not specifying
        the lambda function.
        """
        sym.BINARY.make_node("PLUS", self.r, self.r, lineno=1)

    def test_make_node_PLUS(self):
        """Makes a binary with 2 constants, specifying
        the lambda function.
        """
        n = sym.BINARY.make_node("PLUS", self.r, self.r, lineno=1, func=lambda x, y: x + y)
        self.assertIsInstance(n, sym.NUMBER)
        self.assertEqual(n, 6)

    def test_make_node_PLUS_STR(self):
        """Makes a binary with 2 constants, specifying
        the lambda function.
        """
        n = sym.BINARY.make_node("PLUS", self.r, self.st, lineno=1, func=lambda x, y: x + y)
        self.assertIsNone(n)
        self.assertEqual(self.OUTPUT, "(stdin):1: error: Cannot convert string to a value. Use VAL() function\n")

    def test_make_node_PLUS_STR2(self):
        """Makes a binary with 2 constants, specifying
        the lambda function.
        """
        n = sym.BINARY.make_node("PLUS", self.st, self.st, lineno=1, func=lambda x, y: x + y)
        self.assertEqual(n.value, self.st.value * 2)

    @property
    def OUTPUT(self):
        return OPTIONS.stderr.getvalue()
