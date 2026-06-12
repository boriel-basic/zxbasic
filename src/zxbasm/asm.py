# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from typing import cast

from src.api import errmsg
from src.api import global_ as gl
from src.api.exception import Error
from src.zxbasm.asm_instruction import AsmInstruction
from src.zxbasm.expr import Container, Expr


class Asm(AsmInstruction):
    """Class extension to AsmInstruction with a short name :-P
    and will trap some exceptions and convert them to error msgs.

    It will also record the source line where the instruction was read.
    """

    def __init__(self, lineno: int, asm: str, arg: Expr | str | bytes | tuple[Expr | int, ...] | None = None):
        assert isinstance(lineno, int)
        assert isinstance(asm, str)
        assert arg is None or isinstance(arg, (Expr, bytes, int, str, tuple))

        self.lineno = lineno
        self.is_a_def = asm.upper().strip() in {"DEFB", "DEFS", "DEFW"}

        if self.is_a_def:  # Special case for DEFB, DEFS and DEFW
            assert isinstance(arg, (tuple, bytes, str))
            self.asm = asm
            self.pending = True

            if isinstance(arg, str):
                self.arg = tuple([Expr(Container(ord(x), lineno)) for x in arg])
            else:
                self.arg = arg

            self.original_arg = arg
            self.arg_num = len(self.arg)
            return

        assert arg is None or isinstance(arg, (Expr, int, tuple))

        try:
            super().__init__(asm, arg)
        except Error as v:
            errmsg.error(lineno, v.msg)
            return

        self.pending = any(x for x in self.arg if isinstance(x, Expr) and x.try_eval() is None)

        if not self.pending:
            self.arg = self.argval()

    def bytes(self) -> bytearray:
        """Returns opcodes"""
        if not self.is_a_def:
            if self.pending:
                tmp = self.arg  # Saves current arg temporarily
                self.arg = (0,) * self.arg_num
                result = super().bytes()
                self.arg = tmp  # And recovers it

                return result

            return super().bytes()

        if self.asm == "DEFB":
            if self.pending:
                return bytearray((0,) * self.arg_num)

            return bytearray(x & 0xFF for x in self.argval())

        if self.asm == "DEFS":
            if self.pending:
                N = self.arg[0]
                if isinstance(N, Expr):
                    N = N.eval()
                assert isinstance(N, int)
                return bytearray((0,) * N)

            args = self.argval()
            arg0 = args[0]
            arg1 = args[1]
            assert isinstance(arg0, int)
            assert isinstance(arg1, int)

            if arg1 > 255:
                errmsg.warning_value_will_be_truncated(self.lineno)
            num = arg1 & 0xFF
            return bytearray((num,) * arg0)

        if self.pending:  # DEFW
            return bytearray((0,) * 2 * self.arg_num)

        result = bytearray()
        for i in self.argval():
            x = i & 0xFFFF
            result.extend([x & 0xFF, x >> 8])

        return bytearray(result)

    def argval(self) -> tuple[int | None, ...]:
        """Solve args values or raise errors if not defined yet"""
        if gl.has_errors:
            return (None,)

        if self.is_a_def:
            result = tuple([x.eval() if isinstance(x, Expr) else x for x in self.arg])
            assert all(x is None or isinstance(x, int) for x in result)

            if self.asm == "DEFB" and any(x > 255 for x in result):
                errmsg.warning_value_will_be_truncated(self.lineno)

            return cast(tuple[int | None, ...], result)  # Should have been detected in the assert above

        self.arg = tuple([x if not isinstance(x, Expr) else x.eval() for x in self.arg])
        if gl.has_errors:
            return (None,)

        assert all(isinstance(x, int) for x in self.arg)
        if self.asm.split(" ")[0] in ("JR", "DJNZ"):  # A relative jump?
            if self.arg[0] < -128 or self.arg[0] > 127:
                errmsg.error(self.lineno, "Relative jump out of range")
                return (None,)

        return super(Asm, self).argval() or (None,)
