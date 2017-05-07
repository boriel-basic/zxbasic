#!/usr/bin/env python
# -*- coding: utf-8 -*-
__autor__ = 'boriel'

from unittest import TestCase


# Initialize import syspath
import __init__

from symbols import TYPECAST
from symbols import NUMBER
from symbols import VAR
from symbols.type_ import Type
from api.config import OPTIONS
from six import StringIO
from api.constants import CLASS


class TestSymbolTYPECAST(TestCase):
    def setUp(self):
        self.t = TYPECAST(Type.float_, NUMBER(3, lineno=1), lineno=2)

        if OPTIONS.has_option('stderr'):
            OPTIONS.remove_option('stderr')
        OPTIONS.add_option('stderr', type_=None, default_value=StringIO())

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
        ''' Must return a number
        '''
        v = VAR('a', lineno=1, type_=Type.byte_)
        v.default_value = 3
        v.class_ = CLASS.const
        t = TYPECAST.make_node(Type.float_, v, lineno=2)
        self.assertIsInstance(t, NUMBER)
        self.assertEqual(t, 3)

    def test_make_node_None(self):
        ''' None is allowed as operand
        '''
        self.assertIsNone(TYPECAST.make_node(Type.float_, None, lineno=2))

    def test_make_node_fail_type(self):
        self.assertRaises(AssertionError, TYPECAST.make_node, 'blah', NUMBER(3, lineno=1), lineno=2)

    def test_make_node_fail_oper(self):
        self.assertRaises(AssertionError, TYPECAST.make_node, Type.float_, 'bla', lineno=2)

    def test_make_node_loose_byte(self):
        t = TYPECAST.make_node(Type.byte_, NUMBER(256, lineno=1), lineno=2)
        self.assertEqual(self.OUTPUT, "(stdin):1: warning: Conversion may lose significant digits\n")

    def test_make_node_loose_byte2(self):
        t = TYPECAST.make_node(Type.byte_, NUMBER(3.5, lineno=1), lineno=2)
        self.assertEqual(self.OUTPUT, "(stdin):1: warning: Conversion may lose significant digits\n")

    def test_make_node_loose_byte3(self):
        t = TYPECAST.make_node(Type.ubyte, NUMBER(-3, lineno=1), lineno=2)
        self.assertEqual(self.OUTPUT, '')

    def test_make_node_loose_byte4(self):
        t = TYPECAST.make_node(Type.ubyte, NUMBER(-257, lineno=1), lineno=2)
        self.assertEqual(self.OUTPUT, "(stdin):1: warning: Conversion may lose significant digits\n")

    @property
    def OUTPUT(self):
        return OPTIONS.stderr.value.getvalue()
