from abc import ABC, abstractmethod


class OptimizerInterface(ABC):
    """Implements the Peephole Optimizer"""

    @abstractmethod
    def init(self) -> None:
        pass

    @abstractmethod
    def optimize(self, initial_memory: list[str]) -> str:
        """This will remove useless instructions"""
        pass
