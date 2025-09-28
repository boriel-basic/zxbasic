# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import unittest

from src.arch.z80.optimizer import asm, helpers


class TestASM(unittest.TestCase):
    """Tests optimizer Asm class"""

    def test_spaces(self):
        a = asm.Asm("   nop  \t\n")
        self.assertEqual(a.asm, "nop")

    def test_raises_error_on_empty_instruction(self):
        self.assertRaises(AssertionError, asm.Asm, "  \t \n")

    def test_unknown_instruction(self):
        a = asm.Asm(" unknown instr ")
        self.assertEqual((), a.bytes)

    def test_simplify_arg(self):
        a = helpers.simplify_asm_args("ld a, (126 - 1)")
        self.assertEqual("ld a, (125)", a)

        a = helpers.simplify_asm_args("ld hl, (30 + 40)")
        self.assertEqual("ld hl, (70)", a)

        a = helpers.simplify_asm_args("ld hl, ((30) + (40))")
        self.assertEqual("ld hl, (70)", a)

        a = helpers.simplify_asm_args("ld de, (30) + (40)")
        self.assertEqual("ld de, (70)", a)
