from __future__ import annotations

from src.api.constants import CLASS
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.id_.ref.symbolref import SymbolRef
from src.api.type import Type, PrimitiveType, TypeInstance


class TypeRef(SymbolRef):
    """Internal type representation. Must be derived from type.Type
    """
    def __init__(self, parent: SymbolID):
        super().__init__(parent)

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

    @property
    def type(self) -> Type:
        return self.parent.type_

    def __eq__(self, other):
        return isinstance(other, TypeRef) and self.type == other.type
