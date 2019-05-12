# -*- coding: utf-8 -*-

import unittest
from arch.zx48k.optimizer import asm


class TestASM(unittest.TestCase):
    """ Tests optimizer Asm class
    """
    def test_spaces(self):
        a = asm.Asm('   nop  \t\n')
        self.assertEqual(a.asm, 'nop')

    def test_raises_error_on_empty_instruction(self):
        self.assertRaises(AssertionError, asm.Asm, '  \t \n')

    def test_unknown_instruction(self):
        a = asm.Asm(' unknown instr ')
        self.assertEqual(a.bytes, ())
