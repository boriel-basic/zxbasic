# -*- config: utf-8 -*-
from __future__ import annotations

from typing import TYPE_CHECKING, Final

if TYPE_CHECKING:
    from .basicblock import BasicBlock
    from .labelinfo import LabelInfo

# counter for generating unique random fake values
RAND_COUNT = 0

# Labels which must start a basic block, because they're used in a JP/CALL
LABELS: dict[str, LabelInfo] = {}  # Label -> LabelInfo object

JUMP_LABELS: Final[set[str]] = set()
MEMORY: Final[list[str]] = []  # Instructions emitted by the backend

# PROC labels name space counter
PROC_COUNTER = 0

BLOCKS: Final[list[BasicBlock]] = []  # Memory blocks
