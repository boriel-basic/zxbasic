from src.api import global_
from src.api.constants import CLASS
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.id_.ref.symbolref import SymbolRef
from src.symbols.symbol_ import Symbol


class LabelRef(SymbolRef):
    __slots__ = "_scope_owner", "is_line_number"

    def __init__(self, parent: SymbolID):
        super().__init__(parent)
        self.parent.mangled = f"{global_.LABELS_NAMESPACE}.{global_.MANGLE_CHR}{parent.name}"
        self.callable = False
        self._scope_owner: list[SymbolID] = []  # list of nested functions containing this label (scope)
        self.is_line_number = self.parent.name.isdecimal()  # whether this label is a BASIC line number

    @property
    def token(self) -> str:
        return "LABEL"

    @property
    def class_(self) -> CLASS:
        return CLASS.label

    @property
    def t(self):
        return self.parent.mangled

    @property
    def scope_owner(self) -> list[Symbol]:
        return list(self._scope_owner)

    @scope_owner.setter
    def scope_owner(self, entries: list[Symbol]):
        assert all(isinstance(x, Symbol) for x in entries)
        self._scope_owner = list(entries)
        self.accessed = self._accessed  # if true, refresh scope_owners

    @property
    def accessed(self):
        return self._accessed

    @accessed.setter
    def accessed(self, value):
        self._accessed = bool(value)
        if self._accessed:
            for entry in self.scope_owner:
                entry.accessed = True
