# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from io import StringIO
from unittest import TestCase

from src.api.config import OPTIONS, Action
from src.symbols.sym import ID, NUMBER, TYPECAST
from src.symbols.type_ import Type
from src.zxbpp import zxbpp


class TestSymbolTYPECAST(TestCase):
    def setUp(self):
        zxbpp.init()
        self.t = TYPECAST(Type.float_, NUMBER(3, lineno=1), lineno=2)

        if "stderr" in OPTIONS:
            del OPTIONS.stderr
        OPTIONS(Action.ADD, name="stderr", default=StringIO())
        OPTIONS.hide_warning_codes = True

    def test_operand(self):
        self.assertEqual(self.t.operand, 3)
        self.assertEqual(self.t.type_, Type.float_)
        self.assertEqual(self.t.operand.type_, Type.ubyte)

    def test_make_node__nochange(self):
        n = NUMBER(3, 1, type_=Type.float_)
        self.assertIs(TYPECAST.make_node(Type.float_, n, 1), n)

    def test_operand_setter(self):
        self.t.operand = NUMBER(2, lineno=1)
        self.assertEqual(self.t.operand, 2)

    def test_operand_setter_fail(self):
        self.assertRaises(AssertionError, TYPECAST.operand.fset, self.t, 3)

    def test_make_node(self):
        t = TYPECAST.make_node(Type.float_, NUMBER(3, lineno=1), lineno=2)
        # t is a constant, so typecast is done on the fly
        self.assertEqual(t.type_, Type.float_)
        self.assertEqual(t, self.t.operand)

    def test_make_const(self):
        """Must return a number"""
        v = ID("a", lineno=1, type_=Type.byte_).to_const(NUMBER(3, lineno=1))
        t = TYPECAST.make_node(Type.float_, v, lineno=2)
        self.assertIsInstance(t, NUMBER)
        self.assertEqual(t, 3)

    def test_make_node_None(self):
        """None is allowed as operand"""
        self.assertIsNone(TYPECAST.make_node(Type.float_, None, lineno=2))

    def test_make_node_fail_type(self):
        self.assertRaises(AssertionError, TYPECAST.make_node, "blah", NUMBER(3, lineno=1), lineno=2)

    def test_make_node_fail_oper(self):
        self.assertRaises(AssertionError, TYPECAST.make_node, Type.float_, "bla", lineno=2)

    def test_make_node_loose_byte(self):
        TYPECAST.make_node(Type.byte_, NUMBER(256, lineno=1), lineno=2)
        self.assertEqual(self.OUTPUT, "(stdin):1: warning: Conversion may lose significant digits\n")

    def test_make_node_loose_byte2(self):
        TYPECAST.make_node(Type.byte_, NUMBER(3.5, lineno=1), lineno=2)
        self.assertEqual(self.OUTPUT, "(stdin):1: warning: Conversion may lose significant digits\n")

    def test_make_node_loose_byte3(self):
        TYPECAST.make_node(Type.ubyte, NUMBER(-3, lineno=1), lineno=2)
        self.assertEqual(self.OUTPUT, "")

    def test_make_node_loose_byte4(self):
        TYPECAST.make_node(Type.ubyte, NUMBER(-257, lineno=1), lineno=2)
        self.assertEqual(self.OUTPUT, "(stdin):1: warning: Conversion may lose significant digits\n")

    @property
    def OUTPUT(self):
        return OPTIONS.stderr.getvalue()
