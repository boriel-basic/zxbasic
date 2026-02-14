# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# © Copyright 2008-2024 José Manuel Rodríguez de la Rosa and contributors.
# See the file CONTRIBUTORS.md for copyright details.
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

from src.api import global_ as gl
from src.api.constants import TYPE


class Type:
    """Represents a type in the system."""

    def __init__(self, name: str, size: int):
        self._name = name
        self._size = size

    @property
    def name(self):
        return self._name

    @property
    def size(self) -> int:
        return self._size

    @property
    def is_primitive(self) -> bool:
        return True


BASIC_TYPES: dict[str, Type] = {x.name: Type(x.name, TYPE.size(x)) for x in TYPE.types}


class CompositeType(Type):
    def __init__(self, name: str, size: int):
        super().__init__(name, size)

    @property
    def is_primitive(self) -> bool:
        return False


class AliasType(CompositeType):
    def __init__(self, name: str, base: Type):
        super().__init__(name, base.size)
        self._base = base

    @property
    def base(self) -> Type:
        return self._base


class PointerType(CompositeType):
    def __init__(self, name: str, base: Type):
        super().__init__(name, TYPE.size(gl.PTR_TYPE))
        self._base = base


class ArrayType(CompositeType):
    def __init__(self, name: str, base: Type):
        super().__init__(name, base.size)
        self._base = base
