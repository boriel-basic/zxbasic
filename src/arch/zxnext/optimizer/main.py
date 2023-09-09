from typing import Type

from src.arch.z80.optimizer import Optimizer as OptimizerZ80

from .basicblock import BasicBlock

__all__ = ("Optimizer",)


class Optimizer(OptimizerZ80):
    _BASICBLOCK_TYPE: Type[BasicBlock] = BasicBlock
