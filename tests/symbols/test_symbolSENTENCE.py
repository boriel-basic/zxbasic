#!/usr/bin/env python
# -*- coding: utf-8 -*-

from unittest import TestCase

# Initialize import syspath
import __init__

import symbols

class TestSymbolSENTENCE(TestCase):
    def setUp(self):
        self.TOKEN = 'TOKEN'

    def test_args(self):
        # Must allow None args (which will be ignored)
        s = symbols.SENTENCE(self.TOKEN, None, None, symbols.SENTENCE(self.TOKEN), None)
        self.assertEqual(len(s.args), 1)

    def test_args_fail(self):
        # Fails for non symbol args
        self.assertRaises(AssertionError, symbols.SENTENCE, self.TOKEN, 'blah')

    def test_token(self):
        s = symbols.SENTENCE(self.TOKEN)
        self.assertEqual(s.token, self.TOKEN)
