#!/usr/bin/env python
# -*- coding: utf-8 -*-

from unittest import TestCase
from six import StringIO

# Initialize import syspath
import __init__

from api.config import OPTIONS
import symbols
from symbols.type_ import Type


class TestSymbolBINARY(TestCase):
    def setUp(self):
        self.l = symbols.VAR('a', lineno=1, type_=Type.ubyte)
        self.r = symbols.NUMBER(3, lineno=2)
        self.b = symbols.BINARY('PLUS', self.l, self.r, lineno=3)
        self.st = symbols.STRING("ZXBASIC", lineno=1)
        if OPTIONS.has_option('stderr'):
            OPTIONS.remove_option('stderr')
        OPTIONS.add_option('stderr', type_=None, default_value=StringIO())

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
        ''' Makes a binary with 2 constants, not specifying
        the lambda function.
        '''
        symbols.BINARY.make_node('PLUS', self.r, self.r, lineno=1)

    def test_make_node_PLUS(self):
        ''' Makes a binary with 2 constants, specifying
        the lambda function.
        '''
        n = symbols.BINARY.make_node('PLUS', self.r, self.r, lineno=1, func=lambda x, y: x + y)
        self.assertIsInstance(n, symbols.NUMBER)
        self.assertEqual(n, 6)

    def test_make_node_PLUS_STR(self):
        ''' Makes a binary with 2 constants, specifying
        the lambda function.
        '''
        n = symbols.BINARY.make_node('PLUS', self.r, self.st, lineno=1, func=lambda x, y: x + y)
        self.assertIsNone(n)
        self.assertEqual(self.OUTPUT, '(stdin):1: Cannot convert string to a value. Use VAL() function\n')

    def test_make_node_PLUS_STR2(self):
        ''' Makes a binary with 2 constants, specifying
        the lambda function.
        '''
        n = symbols.BINARY.make_node('PLUS', self.st, self.st, lineno=1, func=lambda x, y: x + y)
        self.assertEqual(n.value, self.st.value * 2)

    @property
    def OUTPUT(self):
        return OPTIONS.stderr.value.getvalue()
