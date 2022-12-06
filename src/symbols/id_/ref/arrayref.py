import functools
from typing import Optional

from src.api import global_ as gl
from src.api.constants import CLASS, SCOPE, TYPE
from src.symbols.boundlist import SymbolBOUNDLIST
from src.symbols.id_.interface import SymbolIdABC as SymbolID
from src.symbols.id_.ref.varref import VarRef


class ArrayRef(VarRef):
    __slots__ = "lbound_used", "ubound_used"

    def __init__(self, parent: SymbolID, bounds: SymbolBOUNDLIST):
        super().__init__(parent)
        assert isinstance(bounds, SymbolBOUNDLIST)
        self.lbound_used = False
        self.ubound_used = False
        self.bounds = bounds
        self.callable = True
        self.offset: Optional[str] = None
        self.byref = False  # Whether this array is passed by ref to a func

    @property
    def token(self) -> str:
        return "VARARRAY"

    @property
    def class_(self) -> CLASS:
        return CLASS.array

    @property
    def count(self):
        """Total number of array cells"""
        return functools.reduce(lambda x, y: x * y, (x.count for x in self.bounds))

    @property
    def size(self):
        return self.count * self.parent.type_.size if self.parent.scope != SCOPE.parameter else TYPE.size(gl.PTR_TYPE)

    @property
    def memsize(self):
        """Total array cell + indexes size"""
        return (2 + (2 if self.lbound_used or self.ubound_used else 0)) * TYPE.size(gl.PTR_TYPE)

    @property
    def data_label(self) -> str:
        return f"{self.parent.mangled}.{gl.ARRAY_DATA_PREFIX}"

    @property
    def data_ptr_label(self) -> str:
        return f"{self.data_label}.__PTR__"

    @property
    def t(self):
        # HINT: Parameters and local variables must have it's .t member as '$name'
        if self.parent.scope == SCOPE.global_:
            return self.data_label

        if self.parent.type_ is None or not self.parent.type_.is_dynamic:
            return self._t

        return "$" + self._t  # Local string variables (and parameters) use '$' (see backend)

    @property
    def bounds(self):
        return self.parent.children[0]

    @bounds.setter
    def bounds(self, value: SymbolBOUNDLIST):
        assert isinstance(value, SymbolBOUNDLIST)
        self.parent.children = [value]
