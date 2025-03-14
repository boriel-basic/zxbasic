from abc import ABC, abstractmethod

from src.api.constants import CLASS, SCOPE
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import SymbolTYPE


class SymbolIdABC(Symbol, ABC):
    __slots__ = "lineno", "mangled", "name", "scope"

    scope: SCOPE
    name: str
    mangled: str
    lineno: int

    @abstractmethod
    def __init__(
        self,
        name: str,
        lineno: int,
        filename: str = None,
        type_: SymbolTYPE | None = None,
        class_: CLASS = CLASS.unknown,
    ):
        super().__init__()

    @property
    @abstractmethod
    def type_(self) -> SymbolTYPE | None:
        pass

    @property
    @abstractmethod
    def token(self) -> str:
        pass

    @property
    @abstractmethod
    def class_(self) -> CLASS:
        pass
