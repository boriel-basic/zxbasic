from abc import ABC, abstractmethod
from typing import Optional

from src.api.constants import CLASS, SCOPE
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import SymbolTYPE


class SymbolIdABC(Symbol, ABC):
    __slots__ = ()

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
        type_: Optional[SymbolTYPE] = None,
        class_: CLASS = CLASS.unknown,
    ):
        super().__init__()

    @property
    @abstractmethod
    def type_(self) -> Optional[SymbolTYPE]:
        pass

    @property
    @abstractmethod
    def token(self) -> str:
        pass

    @property
    @abstractmethod
    def class_(self) -> CLASS:
        pass
