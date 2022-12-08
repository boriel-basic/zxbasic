from __future__ import annotations

from src.api.constants import CLASS
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.id_.ref.symbolref import SymbolRef
from src.api.type import Type, PrimitiveType, ArrayType, StructType


class TypeRef(SymbolRef):
    __slots__ = ("type_",)

    def __iter__(self, parent: SymbolID, type_: Type = PrimitiveType.unknown):
        super().__init__(parent)
        self.type_ = type_

    @property
    def token(self) -> str:
        return "TYPE"

    @property
    def class_(self) -> CLASS:
        return CLASS.type

    @property
    def is_primitive(self) -> bool:
        return isinstance(self.type_, PrimitiveType)

    @property
    def size(self) -> int:
        if isinstance(self.type_, PrimitiveType) and self.type_.size is not None:
            return self.type_.size

        return 0
