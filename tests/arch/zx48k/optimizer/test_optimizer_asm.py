# -*- coding: utf-8 -*-

import unittest
from src.arch.zx48k.optimizer import asm, helpers


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

    def test_simplify_arg(self):
        a = helpers.simplify_asm_args('ld a, (126 - 1)')
        self.assertEqual('ld a, (125)', a)

        a = helpers.simplify_asm_args('ld hl, (30 + 40)')
        self.assertEqual('ld hl, (70)', a)

        a = helpers.simplify_asm_args('ld hl, ((30) + (40))')
        self.assertEqual('ld hl, (70)', a)

        a = helpers.simplify_asm_args('ld de, (30) + (40)')
        self.assertEqual('ld de, (70)', a)
