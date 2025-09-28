# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import pytest

from src.arch.z80.optimizer import cpustate, helpers


class TestCPUState:
    def setup_method(self):
        self.cpu_state = cpustate.CPUState()

    def _eval(self, code):
        lines = [x.strip() for x in code.split("\n") if x.strip()]
        for line in lines:
            self.cpu_state.execute(line)

    def assertEqual(self, actual, expected, err_msg: str = ""):
        assert actual == expected, err_msg

    def assertNotEqual(self, actual, expected, err_msg: str = ""):
        assert actual != expected, err_msg

    def assertTrue(self, expr):
        assert expr

    def assertFalse(self, expr):
        assert not expr

    def assertListEqual(self, actual, expected):
        assert isinstance(actual, list)
        assert actual == list(expected)

    @property
    def regs(self):
        return self.cpu_state.regs

    @property
    def mem(self):
        return self.cpu_state.mem

    def test_cpu_state_mem_write_8_bit_numeric_value(self):
        self.mem.write_8_bit_value("_x", "257")
        self.assertEqual(self.mem.read_8_bit_value("_x"), "1")

    def test_cpu_state_mem_write_8_bit_unknown_value(self):
        self.mem.write_8_bit_value("_x", "_a")
        self.assertEqual(self.mem.read_8_bit_value("_x"), "*UNKNOWN_L__a")

    def test_cpu_state_mem_write_16_bit_numeric_value(self):
        self.mem.write_16_bit_value("_x", "257")
        self.assertEqual(self.mem.read_16_bit_value("_x"), "257")

    def test_cpu_state_mem_write_16_bit_unknown_value(self):
        self.mem.write_16_bit_value("_x", "_a")
        self.assertEqual(self.mem.read_16_bit_value("_x"), "*UNKNOWN_H__a|*UNKNOWN_L__a")

    def test_cpu_state_ld_a_unknown(self):
        code = """
        ld a, (_N)
        """
        self._eval(code)
        self.assertTrue(helpers.is_unknown8(self.regs["a"]))
        self.assertEqual(self.regs["a"], cpustate.get_L_from_unknown_value(self.cpu_state.mem.read_8_bit_value("_N")))

    def test_cpu_state_ld_unknown_a(self):
        code = """
        xor a
        ld (_N), a
        """
        self._eval(code)
        self.assertEqual(self.regs["a"], "0")
        self.assertEqual(self.mem.read_8_bit_value("_N"), "0")
        self.assertTrue(helpers.is_unknown8(self.mem.read_8_bit_value("_N+1")))

    def test_cpu_state_push_pop(self):
        code = """
        ld hl, 256
        push hl
        pop bc
        """
        self._eval(code)
        self.assertListEqual(self.cpu_state.stack, [])
        self.assertEqual(self.regs["hl"], self.regs["bc"])
        self.assertEqual(self.regs["h"], self.regs["b"])
        self.assertEqual(self.regs["l"], self.regs["c"])
        self.assertEqual(self.regs["h"], "1")
        self.assertEqual(self.regs["l"], "0")

    def test_cpu_state_push_pop_unknown(self):
        code = """
        ld hl, (dw4)
        push hl
        pop bc
        """
        self._eval(code)
        self.assertListEqual(self.cpu_state.stack, [])
        self.assertEqual(self.regs["hl"], self.regs["bc"])
        self.assertEqual(self.regs["h"], self.regs["b"])
        self.assertEqual(self.regs["l"], self.regs["c"])

    def test_cpu_state_ld_known(self):
        code = """
        ld hl, 258
        ld b, h
        ld c, l
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], self.regs["bc"])
        self.assertEqual(self.regs["h"], self.regs["b"])
        self.assertEqual(self.regs["l"], self.regs["c"])

    def test_cpu_state_ld_unknown(self):
        code = """
        ld hl, (dw4)
        ld b, h
        ld c, l
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], self.regs["bc"])
        self.assertEqual(self.regs["h"], self.regs["b"])
        self.assertEqual(self.regs["l"], self.regs["c"])

    def test_cpu_state_inc16_unknown(self):
        f = self.regs["f"]
        code = """
        ld hl, (_dw2)
        ld b, h
        ld c, l
        inc hl
        """
        self._eval(code)
        self.assertNotEqual(self.regs["h"], self.regs["b"])
        self.assertNotEqual(self.regs["l"], self.regs["c"])
        self.assertEqual(f, self.regs["f"], "Flags should be unaffected")

    def test_cpu_state_dec16_unknown(self):
        f = self.regs["f"]
        code = """
        ld hl, (_dw2)
        ld b, h
        ld c, l
        dec hl
        """
        self._eval(code)
        self.assertNotEqual(self.regs["h"], self.regs["b"])
        self.assertNotEqual(self.regs["l"], self.regs["c"])
        self.assertEqual(f, self.regs["f"], "Flags should be unaffected")

    def test_cpu_state_inc16_known_CZ_1(self):
        self.cpu_state.C = 0
        self.cpu_state.Z = 0
        f = self.regs["f"]
        code = """
        ld hl, 65535
        inc hl
        """
        self._eval(code)
        self.assertEqual(self.regs["h"], "0")
        self.assertEqual(self.regs["l"], "0")
        self.assertEqual(self.regs["hl"], "0")
        self.assertEqual(f, self.regs["f"], "Flags should be unaffected")
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 0)

    def test_cpu_state_dec16_known_CZ_1(self):
        self.cpu_state.C = 0
        self.cpu_state.Z = 1
        f = self.regs["f"]
        code = """
        ld hl, 0
        dec hl
        """
        self._eval(code)
        self.assertEqual(self.regs["h"], "255")
        self.assertEqual(self.regs["l"], "255")
        self.assertEqual(self.regs["hl"], "65535")
        self.assertEqual(f, self.regs["f"], "Flags should be unaffected")
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_cpu_state_inc8_unknown(self):
        f = self.regs["f"]
        code = """
        ld a, (_dw2)
        ld b, a
        inc a
        """
        self._eval(code)
        self.assertNotEqual(self.regs["a"], self.regs["b"])
        self.assertNotEqual(f, self.regs["f"], "Flags should be affected")

    def test_cpu_state_dec8_unknown(self):
        f = self.regs["f"]
        code = """
        ld a, (_dw2)
        ld b, a
        dec a
        """
        self._eval(code)
        self.assertNotEqual(self.regs["a"], self.regs["b"])
        self.assertNotEqual(f, self.regs["f"], "Flags should be affected")

    def test_cpu_state_inc8_known_CZ_1(self):
        self.cpu_state.C = 0
        self.cpu_state.Z = 0
        f = self.regs["f"]
        code = """
        ld a, 255
        inc a
        """
        self._eval(code)
        self.assertEqual(self.regs["a"], "0")
        self.assertNotEqual(f, self.regs["f"], "Flags should be affected")
        self.assertEqual(self.cpu_state.C, 1)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_cpu_state_dec8_known_CZ_1(self):
        self.cpu_state.C = 0
        self.cpu_state.Z = 1
        f = self.regs["f"]
        code = """
        ld a, 0
        dec a
        """
        self._eval(code)
        self.assertEqual(self.regs["a"], "255")
        self.assertNotEqual(f, self.regs["f"], "Flags should be affected")
        self.assertEqual(self.cpu_state.C, 1)
        self.assertEqual(self.cpu_state.Z, 0)

    def test_cpu_state__ld_sp_hl(self):
        code = """
        ld sp, hl
        """
        self._eval(code)
        self.assertEqual(self.regs["sp"], self.regs["hl"])

    def test_cpu_state__ld_mem(self):
        code = """
        ld hl, 19
        ld (_a), hl
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], "19")
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("_a"), self.regs["hl"])

    def test_cpu_state__ld_hl_de(self):
        code = """
        ld hl, 19
        ld (_a), hl
        ld de, (_a)
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], "19")
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("_a"), self.regs["hl"])
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("_a"), self.regs["de"])

    def test_cpu_state__ld_hl_a(self):
        code = """
        ld hl, _a
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], "_a")

    def test_cpu_state__ix_plus_n(self):
        code = """
        ld (ix + 1), _a
        ld (IY - 2), 259
        """
        self._eval(code)
        self.assertTrue(helpers.is_unknown8(self.mem.read_8_bit_value("ix+1")))
        self.assertEqual(self.mem.read_8_bit_value("iy-2"), str(259 & 0xFF))
        self.assertTrue(all((x[:2], x[2], x[3:]) in self.cpu_state.ix_ptr for x in self.mem.keys()))

    def test_cpu_state__ix_plus_n_2(self):
        code = """
        ld a, (ix + 1)
        """
        self._eval(code)
        self.assertTrue(helpers.is_unknown8(self.mem.read_8_bit_value("ix+1")))
        self.assertEqual(self.mem.read_8_bit_value("ix+1"), self.regs["a"])

    def test_cpu_state__ix_plus_n_rw(self):
        code = """
        ld (ix + 1), 257
        ld a, (ix + 1)
        """
        self._eval(code)
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("ix+1"), "1")
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("ix+1"), self.regs["a"])

    def test_cpu_state__ix_plus_n_inc_rw(self):
        code = """
        ld (ix + 2), 257
        inc ix
        ld a, (ix + 1)
        """
        self._eval(code)
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("ix+1"), "1")
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("ix+1"), self.regs["a"])

    def test_cpu_state__ix_plus_n_dec_rw(self):
        code = """
        ld (ix + 2), 257
        dec ix
        ld a, (ix + 3)
        """
        self._eval(code)
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("ix+3"), "1")
        self.assertEqual(self.cpu_state.mem.read_8_bit_value("ix+3"), self.regs["a"])

    def test_half_hl_unknown16(self):
        code = """
        ld hl, 5
        ld l, (_a)
        """
        self._eval(code)
        self.assertTrue(helpers.is_unknown16(self.regs["hl"]))

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
        h, l = self.regs["hl"].split(helpers.HL_SEP)
        self.assertTrue(helpers.is_number(h))
        self.assertTrue(helpers.is_unknown8(l))
        self.assertEqual(self.regs["h"], "0")

    def test_reset_mem(self):
        self.cpu_state.mem.write_8_bit_value("_test", "5")
        self.cpu_state.reset()
        self.assertNotEqual(self.cpu_state.mem.read_8_bit_value("_test"), "5")

    def test_xor_a(self):
        code = """
        xor a
        """
        self._eval(code)
        self.assertEqual(self.regs["a"], "0")
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_out_c_a(self):
        code = """
        xor a
        out (c), a
        """
        self._eval(code)
        self.assertEqual(self.regs["a"], "0")
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_in_a_c(self):
        code = """
        xor a
        in a, (c)
        """
        self._eval(code)
        self.assertNotEqual(self.regs["a"], "0")
        self.assertTrue(helpers.is_unknown8(self.regs["a"]))
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_xor_a_ld_n_a(self):
        code = """
        xor a
        ld (_push), a
        """
        self._eval(code)
        self.assertEqual(self.regs["a"], "0")
        self.assertFalse(helpers.is_unknown8(self.regs["a"]))
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_ex_de_hl(self):
        code = """
        ld hl, 0x1234
        ld de, 0x5678
        ex de, hl
        """
        self._eval(code)
        self.assertEqual(self.regs["h"], str(0x56))
        self.assertEqual(self.regs["l"], str(0x78))
        self.assertEqual(self.regs["d"], str(0x12))
        self.assertEqual(self.regs["e"], str(0x34))

    def test_ex_de_hl_unknown(self):
        code = """
        ld hl, (x)
        ld de, (y)
        ex de, hl
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], self.cpu_state.mem.read_16_bit_value("y"))
        self.assertEqual(self.regs["de"], self.cpu_state.mem.read_16_bit_value("x"))
        self.assertEqual(self.regs["h"], helpers.HI16_val(self.cpu_state.mem.read_16_bit_value("y")))
        self.assertEqual(self.regs["l"], helpers.LO16_val(self.cpu_state.mem.read_16_bit_value("y")))
        self.assertEqual(self.regs["d"], helpers.HI16_val(self.cpu_state.mem.read_16_bit_value("x")))
        self.assertEqual(self.regs["e"], helpers.LO16_val(self.cpu_state.mem.read_16_bit_value("x")))

    def test_neg_nz(self):
        code = """
        xor a
        ld a, 1
        neg
        """
        self._eval(code)
        self.assertEqual(self.regs["a"], str(0xFF))
        self.assertEqual(self.cpu_state.C, 1)
        self.assertEqual(self.cpu_state.Z, 0)

    def test_neg_z(self):
        code = """
        xor a
        cp 1
        neg
        """
        self._eval(code)
        self.assertEqual(self.regs["a"], str(0))
        self.assertEqual(self.cpu_state.C, 0)
        self.assertEqual(self.cpu_state.Z, 1)

    def test_ix_neg(self):
        code = """
        ld a, (ix-1)
        neg
        """
        self._eval(code)
        self.assertNotEqual(self.regs["a"], self.mem.read_8_bit_value("ix-1"))

    def test_inc_hl(self):
        code = """
        ld hl, 32
        ld (hl), 1
        inc (hl)
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], "32")
        self.assertEqual(self.mem, {"32": "2"})
        self.assertEqual(self.cpu_state.Z, 0)

    def test_dec_hl(self):
        code = """
        ld hl, 32
        ld (hl), 1
        dec (hl)
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], "32")
        self.assertEqual(self.mem, {"32": "0"})
        self.assertEqual(self.cpu_state.Z, 1)

    def test_inc_hl_unknown(self):
        code = """
        ld hl, _a
        ld (hl), 1
        inc (hl)
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], "_a")
        self.assertEqual(self.mem, {self.regs["hl"]: "2"})
        self.assertEqual(self.cpu_state.Z, 0)

    def test_dec_hl_unknown(self):
        code = """
        ld hl, _a
        ld (hl), 1
        dec (hl)
        """
        self._eval(code)
        self.assertEqual(self.regs["hl"], "_a")
        self.assertEqual(self.mem, {self.regs["hl"]: "0"})
        self.assertEqual(self.cpu_state.Z, 1)

    def test_ld_hl_unknown(self):
        code = """
        ld hl, (_temp_ch_len)
        ld a, (hl)
        ld (_temp_wav_len), a
        ld hl, _temp_wav_len
        dec (hl)
        """
        self._eval(code)
        self.assertNotEqual(self.regs["a"], self.mem.read_8_bit_value("_temp_wav_len"))
        self.assertEqual(self.regs["hl"], "_temp_wav_len")
        self.assertEqual(self.regs["a"], self.mem.read_8_bit_value(self.mem.read_16_bit_value("_temp_ch_len")))

    @pytest.mark.parametrize("idx_reg", ("ix", "iy"))
    def test_ld_ix(self, idx_reg):
        code = f"""
        ld {idx_reg}, 0
        ld {idx_reg}h, 1
        ld {idx_reg}l, 1
        """
        self._eval(code)
        self.assertEqual(self.regs[idx_reg], "257")
