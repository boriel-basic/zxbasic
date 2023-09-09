from src.arch.z80.optimizer.asm import Asm
from src.arch.z80.optimizer.cpustate import CPUState as CPUStateZ80

__all__ = ("CPUState",)


class CPUState(CPUStateZ80):
    def execute(self, asm_code: str) -> None:
        """Execute the given assembly code."""

        asm = Asm(asm_code)
        if asm.is_label:
            return

        i = asm.inst
        o = asm.oper

        if i == "mul":
            val_d = self.getv(o[0])
            val_e = self.getv(o[1])
            if val_d is not None and val_e is not None:
                val = val_d * val_e
                self.set("de", val)
                self.Z = int(val == 0)
                self.C = int(val < 0)
                self.S = int(val < 0)
                return

        super().execute(asm_code)
