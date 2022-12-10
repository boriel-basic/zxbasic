from __future__ import annotations

from src.api.constants import CLASS
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.id_.ref.symbolref import SymbolRef
from src.api.type import Type, PrimitiveType, ArrayType, StructType


class TypeRef(SymbolRef):
    __slots__ = "type",

    def __iter__(self, parent: SymbolID, type_: Type = PrimitiveType.unknown):
        super().__init__(parent)
        self.type = type_

    @property
    def token(self) -> str:
        return "TYPE"

    @property
    def class_(self) -> CLASS:
        return CLASS.type

    @property
    def is_primitive(self) -> bool:
        return isinstance(self.type, PrimitiveType)

    @property
    def size(self) -> int:
        return self.type.size

    def __eq__(self, other):
        return isinstance(other, TypeRef) and self.size == other.size
