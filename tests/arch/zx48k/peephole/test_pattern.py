# -*- coding: utf-8 -*-

import unittest

from src.arch.zx48k.peephole import pattern


class TestBasicLinePattern(unittest.TestCase):
    def test_var1__ok(self):
        patt = pattern.BasicLinePattern(' push   $1  ')
        self.assertEqual(patt.vars, {'$1'})
        self.assertEqual(patt.line, 'push $1')
        self.assertEqual(patt.output, ['push', ' ', '$1'])

    def test_no_var_double_dollar(self):
        patt = pattern.BasicLinePattern('  $$1 ')
        self.assertEqual(patt.vars, set())
        self.assertEqual(patt.line, '$$1')
        self.assertEqual(patt.output, ['$', '1'])

    def test_var_and_double_dollar(self):
        patt = pattern.BasicLinePattern('  $2$$$1 ')
        self.assertEqual(patt.vars, {'$2', '$1'})
        self.assertEqual(patt.line, '$2$$$1')
        self.assertEqual(patt.output, ['$2', '$', '$1'])

    def test_slash(self):
        patt = pattern.BasicLinePattern(r'  \$1')
        self.assertEqual(patt.vars, {'$1'})
        self.assertEqual(patt.line, r'\$1')
        self.assertEqual(patt.output, ['\\', '$1'])

    def test_parse_comma_correctly(self):
        patt = pattern.BasicLinePattern(' ld $1, a')
        self.assertEqual(patt.vars, {'$1'})
        self.assertEqual(patt.line, r'ld $1, a')
        self.assertEqual(patt.output, ['ld', ' ', '$1', ',', ' ', 'a'])


class TestLinePattern(unittest.TestCase):
    def test_matches_parsed(self):
        patt = pattern.LinePattern('push $1')
        match = patt.match('push af')
        self.assertEqual(match, {'$1': 'af'})

    def test_no_match(self):
        patt = pattern.LinePattern('push $1')
        match = patt.match('pop af')
        self.assertIsNone(match)

    def test_double_match(self):
        patt = pattern.LinePattern('push $1   $1')  # three spaces
        match = patt.match('push af  af')  # only two spaces
        self.assertEqual(match, {'$1': 'af'})

    def test_match_two_patterns(self):
        patt = pattern.LinePattern('$2 $1')
        match = patt.match('push af')
        self.assertEqual(match, {'$1': 'af', '$2': 'push'})

    def test_match_two_patterns_twice(self):
        patt = pattern.LinePattern('$2 $1 $2 $1')
        match = patt.match('push af push af')
        self.assertEqual(match, {'$1': 'af', '$2': 'push'})

    def test_matches_empty_novars(self):
        patt = pattern.LinePattern('push af')
        match = patt.match('push af')
        self.assertEqual(match, {})


class TestBlockPattern(unittest.TestCase):
    def test_matches_parsed(self):
        patt = pattern.BlockPattern(['push $1', 'pop $2'])
        match = patt.match(['push af', 'pop bc'])
        self.assertEqual(match, {'$1': 'af', '$2': 'bc'})

    def test_matches_var_across_lines(self):
        patt = pattern.BlockPattern(['push $1', 'pop $1'])
        match = patt.match(['push af', 'pop af'])
        self.assertEqual(match, {'$1': 'af'})

    def test_no_matches_var_across_lines(self):
        patt = pattern.BlockPattern(['push $1', 'pop $1'])
        match = patt.match(['push af', 'pop bc'])
        self.assertIsNone(match)

    def test_matches_lines_empty_novars(self):
        patt = pattern.BlockPattern(['push af', 'pop bc'])
        match = patt.match(['push af', 'pop bc'])
        self.assertEqual(match, {})
