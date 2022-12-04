from dataclasses import dataclass
from typing import Any, List

from src.symbols.id_ import SymbolID


@dataclass(frozen=True)
class DataRef:
    label: SymbolID
    datas: List[Any]

    def __post_init__(self):
        assert self.label.token == "LABEL"

    def __iter__(self):
        return (x for x in [self.label, self.datas])
