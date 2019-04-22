# -*- coding: utf-8 -*-

import unittest

from arch.zx48k.optimizer import cpustate


class TestCPUState(unittest.TestCase):
    def setUp(self):
        self.cpu_state = cpustate.CPUState()

    def _eval(self, code):
        lines = [x.strip() for x in code.split('\n') if x.strip()]
        for line in lines:
            self.cpu_state.execute(line)

    @property
    def regs(self):
        return self.cpu_state.regs

    def test_cpu_state_push_pop(self):
        code = """
        ld hl, 256
        push hl
        pop bc
        """
        self._eval(code)
        self.assertListEqual(self.cpu_state.stack, [])
        self.assertEqual(self.regs['hl'], self.regs['bc'])
        self.assertEqual(self.regs['h'], self.regs['b'])
        self.assertEqual(self.regs['l'], self.regs['c'])
        self.assertEqual(self.regs['h'], '1')
        self.assertEqual(self.regs['l'], '0')

    def test_cpu_state_push_pop_unknown(self):
        code = """
        ld hl, (dw4)
        push hl
        pop bc
        """
        self._eval(code)
        self.assertListEqual(self.cpu_state.stack, [])
        self.assertEqual(self.regs['hl'], self.regs['bc'])
        self.assertEqual(self.regs['h'], self.regs['b'])
        self.assertEqual(self.regs['l'], self.regs['c'])

    def test_cpu_state_ld_known(self):
        code = """
        ld hl, 258
        ld b, h
        ld c, l
        """
        self._eval(code)
        self.assertEqual(self.regs['hl'], self.regs['bc'])
        self.assertEqual(self.regs['h'], self.regs['b'])
        self.assertEqual(self.regs['l'], self.regs['c'])

    def test_cpu_state_ld_unknown(self):
        code = """
        ld hl, (dw4)
        ld b, h
        ld c, l
        """
        self._eval(code)
        self.assertEqual(self.regs['hl'], self.regs['bc'])
        self.assertEqual(self.regs['h'], self.regs['b'])
        self.assertEqual(self.regs['l'], self.regs['c'])

    def test_cpu_state_inc16_unknown(self):
        f = self.regs['f']
        code = """
        ld hl, (_dw2)
        ld b, h
        ld c, l
        inc hl
        """
        self._eval(code)
        self.assertNotEqual(self.regs['h'], self.regs['b'])
        self.assertNotEqual(self.regs['l'], self.regs['c'])
        self.assertEqual(f, self.regs['f'], "Flags should be unaffected")

    def test_cpu_state_dec16_unknown(self):
        f = self.regs['f']
        code = """
        ld hl, (_dw2)
        ld b, h
        ld c, l
        dec hl
        """
        self._eval(code)
        self.assertNotEqual(self.regs['h'], self.regs['b'])
        self.assertNotEqual(self.regs['l'], self.regs['c'])
        self.assertEqual(f, self.regs['f'], "Flags should be unaffected")

    def test_cpu_state_inc16_known(self):
        f = self.regs['f']
        code = """
        ld hl, 65535
        inc hl
        """
        self._eval(code)
        self.assertEqual(self.regs['h'], '0')
        self.assertEqual(self.regs['l'], '0')
        self.assertEqual(self.regs['hl'], '0')
        self.assertEqual(f, self.regs['f'], "Flags should be unaffected")

    def test_cpu_state_dec16_known(self):
        f = self.regs['f']
        code = """
        ld hl, 0
        dec hl
        """
        self._eval(code)
        self.assertEqual(self.regs['h'], '255')
        self.assertEqual(self.regs['l'], '255')
        self.assertEqual(self.regs['hl'], '65535')
        self.assertEqual(f, self.regs['f'], "Flags should be unaffected")
