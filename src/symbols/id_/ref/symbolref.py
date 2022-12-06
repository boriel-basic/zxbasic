from src.api import global_
from src.api.constants import CLASS
from src.symbols.id_.interface import SymbolIdABC as SymbolID


class SymbolRef:
    """ABC for the metadata reference object.
    This defines an interface that will contain extra
    attributes according to the object whose ID references
    """

    __slots__ = "_accessed", "_t", "addr", "callable", "offset", "parent"

    def __init__(self, parent: SymbolID):
        assert isinstance(parent, SymbolID)
        self.parent: SymbolID = parent
        self.callable = False  # For functions, subs, arrays and strings this will be True
        self._t: str = global_.optemps.new_t()
        self.addr = None
        self._accessed = False
        self.offset = None

    @property
    def class_(self) -> CLASS:
        return CLASS.unknown

    @property
    def token(self) -> str:
        return "ID"

    @property
    def t(self) -> str:
        return self._t

    def __repr__(self) -> str:
        return f"ID:{str(self.parent)}"

    @property
    def accessed(self) -> bool:
        return self._accessed

    @accessed.setter
    def accessed(self, value: bool):
        self._accessed = value
