from typing import Optional

import src.api.global_ as gl
from src.api.constants import CLASS, SCOPE
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.id_.ref.symbolref import SymbolRef
from src.symbols.symbol_ import Symbol
from src.symbols.type_ import SymbolBASICTYPE as BasicType


class VarRef(SymbolRef):
    __slots__ = "alias", "byref", "default_value", "offset"

    def __init__(self, parent: SymbolID, default_value: Symbol | None = None):
        super().__init__(parent)
        self.default_value = default_value  # If defined, it be initialized with this value (Arrays = List of Bytes)
        self.offset: Optional[str] = None  # If local variable or parameter, +/- offset from top of the stack
        self.byref = False
        self.alias = None  # If not None, this var is an alias of another

    @property
    def token(self) -> str:
        return "VAR"

    @property
    def class_(self) -> CLASS:
        return CLASS.var

    @property
    def t(self) -> str:
        if self.parent.scope == SCOPE.global_:
            return self.parent.mangled

        if self.parent.type_ is None or not self.parent.type_.is_dynamic:
            return self._t

        return f"${self._t}"  # Local string variables (and parameters) use '$' (see backend)

    @property
    def size(self) -> int:
        if self.parent.type_ is None:
            return 0

        if self.parent.scope == SCOPE.parameter:
            if self.byref:
                return BasicType(gl.PTR_TYPE).size

            return self.parent.type_.size + (
                self.parent.type_.size % gl.PARAM_ALIGN
            )  # Make it even-sized (Float and Byte)

        return self.parent.type_.size
