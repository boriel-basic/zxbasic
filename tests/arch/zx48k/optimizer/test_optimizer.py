# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.arch.z80 import optimizer
from src.arch.z80.peephole import engine
from tests.arch.zx48k.optimizer.common import mock_options_level


class TestOptimizer:
    def setup_class(cls):
        engine.main()

    def test_unrequired_or_a(self):
        code_src = """
        call .core.__LTI8
        or a
        ld bc, 0
        di
        ld hl, (.core.__CALL_BACK__)
        ld sp, hl
        exx
        pop hl
        pop iy
        pop ix
        exx
        ei
        ret
        """
        code = [x.strip() for x in code_src.split("\n") if x.strip()]

        with mock_options_level(4):
            optimized_code = optimizer.Optimizer().optimize(code)
            assert optimized_code.split("\n")[:2] == ["call .core.__LTI8", "ld bc, 0"]

    def test_ld_sp_requires_sp(self):
        code_src = """
        ld sp, hl
        pop iy
        """
        code = [x.strip() for x in code_src.split("\n") if x.strip()]

        with mock_options_level(4):
            optimized_code = optimizer.Optimizer().optimize(code)
            assert optimized_code.split("\n")[:2] == ["ld sp, hl", "pop iy"]

    def test_hd_sp_requires_sp(self):
        code_src = """
        add hl, sp
        pop iy
        jp (hl)
        """
        code = [x.strip() for x in code_src.split("\n") if x.strip()]

        with mock_options_level(3):
            optimized_code = optimizer.Optimizer().optimize(code)
            assert optimized_code.split("\n") == ["add hl, sp", "pop iy", "jp (hl)"]
