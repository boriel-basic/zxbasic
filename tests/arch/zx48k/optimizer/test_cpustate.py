# -*- coding: utf-8 -*-

import unittest

from src.arch.zx48k.optimizer import cpustate, helpers


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

    def test_cpu_state_ld_a_unknown(self):
        code = """
        ld a, (_N)
        """
        self._eval(code)
        self.assertTrue(helpers.is_unknown8(self.regs['a']))
        self.assertEqual(self.regs['a'], cpustate.get_L_from_unknown_value(self.cpu_state.mem['_N']))

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

    def test_cpu_state_inc16_known_CZ_1(self):
        self.cpu_state.C = 0
        self.cpu_state.Z = 0
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
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 0)

    def test_cpu_state_dec16_known_CZ_1(self):
        self.cpu_state.C = 0
        self.cpu_state.Z = 1
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
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_cpu_state_inc8_unknown(self):
        f = self.regs['f']
        code = """
        ld a, (_dw2)
        ld b, a
        inc a
        """
        self._eval(code)
        self.assertNotEqual(self.regs['a'], self.regs['b'])
        self.assertNotEqual(f, self.regs['f'], "Flags should be affected")

    def test_cpu_state_dec8_unknown(self):
        f = self.regs['f']
        code = """
        ld a, (_dw2)
        ld b, a
        dec a
        """
        self._eval(code)
        self.assertNotEqual(self.regs['a'], self.regs['b'])
        self.assertNotEqual(f, self.regs['f'], "Flags should be affected")

    def test_cpu_state_inc8_known_CZ_1(self):
        self.cpu_state.C = 0
        self.cpu_state.Z = 0
        f = self.regs['f']
        code = """
        ld a, 255
        inc a
        """
        self._eval(code)
        self.assertEqual(self.regs['a'], '0')
        self.assertNotEqual(f, self.regs['f'], "Flags should be affected")
        self.assertEqual(self.cpu_state.C, 1)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_cpu_state_dec8_known_CZ_1(self):
        self.cpu_state.C = 0
        self.cpu_state.Z = 1
        f = self.regs['f']
        code = """
        ld a, 0
        dec a
        """
        self._eval(code)
        self.assertEqual(self.regs['a'], '255')
        self.assertNotEqual(f, self.regs['f'], "Flags should be affected")
        self.assertEqual(self.cpu_state.C, 1)
        self.assertEqual(self.cpu_state.Z, 0)

    def test_cpu_state__ld_sp_hl(self):
        code = """
        ld sp, hl
        """
        self._eval(code)
        self.assertEqual(self.regs['sp'], self.regs['hl'])

    def test_cpu_state__ld_mem(self):
        code = """
        ld hl, 19
        ld (_a), hl
        """
        self._eval(code)
        self.assertEqual(self.regs['hl'], '19')
        self.assertEqual(self.cpu_state.mem['_a'], self.regs['hl'])

    def test_cpu_state__ld_hl_de(self):
        code = """
        ld hl, 19
        ld (_a), hl
        ld de, (_a)
        """
        self._eval(code)
        self.assertEqual(self.regs['hl'], '19')
        self.assertEqual(self.cpu_state.mem['_a'], self.regs['hl'])
        self.assertEqual(self.cpu_state.mem['_a'], self.regs['de'])

    def test_cpu_state__ld_hl_a(self):
        code = """
        ld hl, _a
        """
        self._eval(code)
        self.assertTrue(cpustate.is_unknown16(self.regs['hl']))

    def test_cpu_state__ix_plus_n(self):
        code = """
        ld (ix + 1), _a
        ld (IY - 2), 259
        """
        self._eval(code)
        self.assertTrue(helpers.is_unknown8(self.cpu_state.mem['ix+1']))
        self.assertEqual(self.cpu_state.mem['iy-2'], str(259 & 0xFF))
        self.assertTrue(all((x[:2], x[2], x[3:]) in self.cpu_state.ix_ptr for x in self.cpu_state.mem.keys()))

    def test_cpu_state__ix_plus_n_2(self):
        code = """
        ld a, (ix + 1)
        """
        self._eval(code)
        self.assertTrue(helpers.is_unknown8(self.cpu_state.mem['ix+1']))
        self.assertEqual(self.cpu_state.mem['ix+1'], self.regs['a'])

    def test_cpu_state__ix_plus_n_rw(self):
        code = """
        ld (ix + 1), 257
        ld a, (ix + 1)
        """
        self._eval(code)
        self.assertEqual(self.cpu_state.mem['ix+1'], '1')
        self.assertEqual(self.cpu_state.mem['ix+1'], self.regs['a'])

    def test_cpu_state__ix_plus_n_inc_rw(self):
        code = """
        ld (ix + 2), 257
        inc ix
        ld a, (ix + 1)
        """
        self._eval(code)
        self.assertEqual(self.cpu_state.mem['ix+1'], '1')
        self.assertEqual(self.cpu_state.mem['ix+1'], self.regs['a'])

    def test_cpu_state__ix_plus_n_dec_rw(self):
        code = """
        ld (ix + 2), 257
        dec ix
        ld a, (ix + 3)
        """
        self._eval(code)
        self.assertEqual(self.cpu_state.mem['ix+3'], '1')
        self.assertEqual(self.cpu_state.mem['ix+3'], self.regs['a'])

    def test_half_hl_unknown16(self):
        code = """
        ld hl, 5
        ld l, (_a)
        """
        self._eval(code)
        self.assertTrue(helpers.is_unknown16(self.regs['hl']))

    def test_half_hl_set_mem(self):
        code = """
        ld l, a
        ld h, 0
        ld (_dw3), hl
        ld hl, (_dw3)
        """
        self._eval(code)
        # Must not crash

    def test_hl_is_half_known(self):
        code = """
        ld h, 0
        """
        self._eval(code)
        h, l = self.regs['hl'].split(helpers.HL_SEP)
        self.assertTrue(helpers.is_number(h))
        self.assertTrue(helpers.is_unknown8(l))
        self.assertEqual(self.regs['h'], '0')

    def test_reset_mem(self):
        self.cpu_state.mem['_test'] = '5'
        self.cpu_state.reset()
        self.assertNotEqual(self.cpu_state.mem['_test'], '5')

    def test_xor_a(self):
        code = """
        xor a
        """
        self._eval(code)
        self.assertEqual(self.regs['a'], '0')
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_out_c_a(self):
        code = """
        xor a
        out (c), a
        """
        self._eval(code)
        self.assertEqual(self.regs['a'], '0')
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_in_a_c(self):
        code = """
        xor a
        in a, (c)
        """
        self._eval(code)
        self.assertNotEqual(self.regs['a'], '0')
        self.assertTrue(helpers.is_unknown8(self.regs['a']))
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_xor_a_ld_n_a(self):
        code = """
        xor a
        ld (_push), a
        """
        self._eval(code)
        self.assertEqual(self.regs['a'], '0')
        self.assertFalse(helpers.is_unknown8(self.regs['a']))
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_ex_de_hl(self):
        code = """
        ld hl, 0x1234
        ld de, 0x5678
        ex de, hl
        """
        self._eval(code)
        self.assertEqual(self.regs['h'], str(0x56))
        self.assertEqual(self.regs['l'], str(0x78))
        self.assertEqual(self.regs['d'], str(0x12))
        self.assertEqual(self.regs['e'], str(0x34))

    def test_ex_de_hl_unknown(self):
        code = """
        ld hl, (x)
        ld de, (y)
        ex de, hl
        """
        self._eval(code)
        self.assertEqual(self.regs['hl'], self.cpu_state.mem['y'])
        self.assertEqual(self.regs['de'], self.cpu_state.mem['x'])
        self.assertEqual(self.regs['h'], helpers.HI16_val(self.cpu_state.mem['y']))
        self.assertEqual(self.regs['l'], helpers.LO16_val(self.cpu_state.mem['y']))
        self.assertEqual(self.regs['d'], helpers.HI16_val(self.cpu_state.mem['x']))
        self.assertEqual(self.regs['e'], helpers.LO16_val(self.cpu_state.mem['x']))
