from collections.abc import Callable
from dataclasses import dataclass

from .quad import Quad

__all__ = ("ICInfo",)


@dataclass(frozen=True)
class ICInfo:
    nargs: int
    func: Callable[[Quad], list[str]]
