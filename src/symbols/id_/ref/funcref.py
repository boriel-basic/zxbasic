from typing import Optional

from src.api.constants import CLASS, CONVENTION
from src.symbols.block import SymbolBLOCK
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.id_.ref.symbolref import SymbolRef
from src.symbols.paramlist import SymbolPARAMLIST


class FuncRef(SymbolRef):
    __slots__ = "_class", "convention", "forwarded", "locals_size", "local_symbol_table", "params_size"

    def __init__(self, parent: SymbolID, lineno: Optional[int], class_: CLASS):
        assert class_ in (CLASS.function, CLASS.sub, CLASS.unknown)

        super().__init__(parent)
        self._class = class_
        self.callable = True
        self.local_symbol_table = None
        self.convention = CONVENTION.unknown
        self.forwarded = False  # True if declared (with DECLARE) in advance (functions or subs)
        self.parent.children = [SymbolPARAMLIST(), SymbolBLOCK()]
        self.params_size = 0
        self.locals_size = 0

        if lineno is not None:
            self.parent.lineno = lineno

    @property
    def token(self) -> str:
        return "FUNCTION"

    @property
    def class_(self) -> CLASS:
        return self._class

    def __repr__(self):
        return f"FUNC:{self.parent.name}"

    @property
    def t(self):
        return self.parent.mangled

    @property
    def params(self) -> SymbolPARAMLIST:
        return self.parent.children[0]

    @params.setter
    def params(self, value: SymbolPARAMLIST):
        assert isinstance(value, SymbolPARAMLIST)
        self.parent.children[0] = value

    @property
    def body(self) -> SymbolBLOCK:
        return self.parent.children[1]

    @body.setter
    def body(self, value: Optional[SymbolBLOCK]):
        if value is None:
            value = SymbolBLOCK()
        assert isinstance(value, SymbolBLOCK)
        self.parent.children[1] = value

    @property
    def size(self) -> int:
        if self.parent.type_ is None:
            return 0

        return self.parent.type_.size
