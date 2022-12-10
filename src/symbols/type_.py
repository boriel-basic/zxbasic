# -*- coding: utf-8 -*-

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from src.api.type import Type, PrimitiveType, ArrayType, StructType
from src.symbols.symbol_ import Symbol


class SymbolTYPE(Symbol):
    __slots__ = "name", "type_"

    def __init__(self, name: str, type_: Type):
        assert isinstance(type_, (PrimitiveType, ArrayType, StructType))
        super().__init__()
        self.name = name
        self.type_ = type_

    def __eq__(self, other):
        return isinstance(other, SymbolTYPE) and self.type_ == other.type_

    @property
    def size(self) -> int:
        return self.type_.size
