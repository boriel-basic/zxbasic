from typing import Any, NamedTuple

from src.api import errmsg
from src.api import global_ as gl
from src.api.exception import Error
from src.zxbasm.asm_instruction import AsmInstruction
from src.zxbasm.expr import Expr


class Container(NamedTuple):
    """Single class container"""

    item: Any
    lineno: int


class Asm(AsmInstruction):
    """Class extension to AsmInstruction with a short name :-P
    and will trap some exceptions and convert them to error msgs.

    It will also record source line
    """

    def __init__(self, lineno, asm, arg=None):
        self.lineno = lineno

        if asm not in ("DEFB", "DEFS", "DEFW"):
            try:
                super().__init__(asm, arg)
            except Error as v:
                errmsg.error(lineno, v.msg)
                return

            self.pending = len([x for x in self.arg if isinstance(x, Expr) and x.try_eval() is None]) > 0

            if not self.pending:
                self.arg = self.argval()
        else:
            self.asm = asm
            self.pending = True

            if isinstance(arg, str):
                self.arg = tuple([Expr(Container(ord(x), lineno)) for x in arg])
            else:
                self.arg = arg

            self.arg_num = len(self.arg)

    def bytes(self) -> bytearray:
        """Returns opcodes"""
        if self.asm not in ("DEFB", "DEFS", "DEFW"):
            if self.pending:
                tmp = self.arg  # Saves current arg temporarily
                self.arg = (0,) * self.arg_num
                result = super(Asm, self).bytes()
                self.arg = tmp  # And recovers it

                return result

            return super(Asm, self).bytes()

        if self.asm == "DEFB":
            if self.pending:
                return bytearray((0,) * self.arg_num)

            return bytearray(x & 0xFF for x in self.argval())

        if self.asm == "DEFS":
            if self.pending:
                N = self.arg[0]
                if isinstance(N, Expr):
                    N = N.eval()
                return (0,) * N

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

    def argval(self):
        """Solve args values or raise errors if not
        defined yet
        """
        if gl.has_errors:
            return [None]

        if self.asm in ("DEFB", "DEFS", "DEFW"):
            result = tuple([x.eval() if isinstance(x, Expr) else x for x in self.arg])
            if self.asm == "DEFB" and any(x > 255 for x in result):
                errmsg.warning_value_will_be_truncated(self.lineno)
            return result

        self.arg = tuple([x if not isinstance(x, Expr) else x.eval() for x in self.arg])
        if gl.has_errors:
            return [None]

        if self.asm.split(" ")[0] in ("JR", "DJNZ"):  # A relative jump?
            if self.arg[0] < -128 or self.arg[0] > 127:
                errmsg.error(self.lineno, "Relative jump out of range")
                return [None]

        return super(Asm, self).argval()
