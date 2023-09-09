from typing import Iterable

from src.arch.z80.optimizer import Optimizer
from src.arch.z80.optimizer.basicblock import BasicBlock as BasicBlockZ80
from src.arch.z80.optimizer.helpers import simplify_asm_args

from .cpustate import CPUState
from .memcell import MemCell

__all__ = ("BasicBlock",)


class BasicBlock(BasicBlockZ80):
    def __init__(self, memory: Iterable[str], optimizer: Optimizer) -> None:
        super().__init__(memory, optimizer)
        self.cpu = CPUState()

    def _set_code(self, value: Iterable[str]):
        assert isinstance(value, Iterable)
        mems = tuple(value)
        assert all(isinstance(x, str) for x in mems)
        if self.clean_asm_args:
            self.mem = [MemCell(simplify_asm_args(asm), i) for i, asm in enumerate(mems)]
        else:
            self.mem = [MemCell(asm, i) for i, asm in enumerate(mems)]

        self._bytes = None
        self._sizeof = None
        self._max_tstates = None
