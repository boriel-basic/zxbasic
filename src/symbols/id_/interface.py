from abc import ABC, abstractmethod

from src.api.constants import CLASS, SCOPE
from src.api.type import Type
from src.symbols.symbol_ import Symbol


class SymbolIdABC(Symbol, ABC):
    __slots__ = ()

    scope: SCOPE
    name: str
    mangled: str
    lineno: int

    @property
    @abstractmethod
    def type_(self) -> Type:
        pass

    @property
    @abstractmethod
    def token(self) -> str:
        pass

    @property
    @abstractmethod
    def class_(self) -> CLASS:
        pass
