from dataclasses import dataclass

from src.arch.z80.backend.icinstruction import ICInstruction
from src.symbols.symbol_ import Symbol

__all__ = ("Quad",)


@dataclass(init=False, frozen=True)
class Quad:
    """Implements a Quad code instruction."""

    instr: ICInstruction
    args: tuple[str, ...]

    def __init__(self, instr: ICInstruction, *args) -> None:
        """Creates a quad-uple checking it has the current params.
        Operators should be passed as Quad(ICInstruction, tSymbol, val1, val2)
        """
        args = tuple(str(x.t) if isinstance(x, Symbol) else str(x) for x in args)
        object.__setattr__(self, "instr", instr)
        object.__setattr__(self, "args", args)

    def __str__(self) -> str:
        """String representation"""
        return str(tuple(self))

    def __len__(self) -> int:
        """Returns the number of arguments + 1 (the instruction)"""
        return len(self.args) + 1

    def __iter__(self):
        return iter((self.instr, *self.args))

    def __getitem__(self, item):
        return (self.instr, *self.args)[item]
