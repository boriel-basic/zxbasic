# -*- coding: utf-8 -*-

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from src.api.constants import CLASS
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.api.type import PrimitiveType, TypeInstance, Type


class SymbolTYPEREF:
    __slots__ = "type_id", "implicit"

    def __init__(self, type_: SymbolID, implicit: bool = True):
        assert isinstance(type_, SymbolID) and type_.class_ == CLASS.type
        super().__init__()
        self.type_id = type_
        self.implicit = implicit

    def __eq__(self, other):
        if isinstance(other, SymbolTYPEREF):
            return self.type_id == other.type_id

        if isinstance(other, SymbolID) and other.class_ == CLASS.type:
            return self.type_id.type_ == other.type_

        if isinstance(other, TypeInstance):
            return self.type_id.type_ == other

        return False

    @property
    def size(self) -> int:
        return self.type_id.type_.size

    @property
    def name(self) -> str:
        return self.type_id.name

    @property
    def type(self) -> Type:
        return self.type_id.type_

    @classmethod
    def basic_type(cls, type_: PrimitiveType):
        return
