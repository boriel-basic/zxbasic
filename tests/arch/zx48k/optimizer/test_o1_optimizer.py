# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.arch.z80.backend import Backend
from tests.arch.zx48k.optimizer.common import mock_options_level


class TestO1Optimizer:
    @staticmethod
    def _asm_code(asm: str) -> list[str]:
        return [x.strip() for x in asm.split("\n") if x.strip()]

    def setup_method(self) -> None:
        self.backend = Backend()

    def test_call_match(self):
        code_src = """
        call .core.__LEI8
        sub 1
        sbc a, a
        inc a
        """
        code = self._asm_code(code_src)
        with mock_options_level(1):
            output = []
            self.backend._output_join(output, code, optimize=True)
            assert output == [
                "call .core.__LEI8",
            ]
