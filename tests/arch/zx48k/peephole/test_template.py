# -*- coding: utf-8 -*-

import unittest
from src.arch.zx48k.peephole import template


class TestLineTemplate(unittest.TestCase):
    def test_match_vars(self):
        tpl = template.LineTemplate('push $1')
        output = tpl.filter({'$1': 'af', '$2': 'anything'})
        self.assertEqual(output, 'push af')

    def test_match_vars_unbound_error(self):
        tpl = template.LineTemplate('push $1')
        self.assertRaises(template.UnboundVarError, tpl.filter, ({'$2': 'af'}))


class TestBlockTemplate(unittest.TestCase):
    def test_match_vars_several(self):
        tpl = template.BlockTemplate(['push $1', 'pop $2'])
        output = tpl.filter({'$1': 'af', '$2': 'bc'})
        self.assertEqual(output, ['push af', 'pop bc'])

    def test_match_vars_unbound_error(self):
        tpl = template.BlockTemplate(['push $1', 'pop $2'])
        self.assertRaises(template.UnboundVarError, tpl.filter, ({'$2': 'af'}))
