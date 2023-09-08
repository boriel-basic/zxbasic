from dataclasses import dataclass
from typing import Callable

from .exception import throw_invalid_quad_params
from .quad import Quad

__all__ = ("ICInfo",)


@dataclass(frozen=True)
class ICInfo:
    nargs: int
    func: Callable[[Quad], list[str]]

    def __call__(self, instr: str, *args: str) -> Quad:
        quad = Quad(instr, args)
        if len(quad) != self.nargs:
            throw_invalid_quad_params(quad, self.nargs)

        return quad
