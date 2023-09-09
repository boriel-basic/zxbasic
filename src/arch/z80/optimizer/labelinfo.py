# -*- coding: utf-8 -*-
from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .basicblock import BasicBlock


@dataclass
class LabelInfo:
    """Class describing label information
    Stores the label name, the address counter into memory (rather useless)
    and which basic block contains it.
    """

    label: str
    addr: int  # Memory address or 0
    basic_block: BasicBlock | None = None  # Basic Block this label is in
    position: int = 0  # Position within the Basic Block
    used_by: set[BasicBlock] = field(default_factory=set)  # Which BB uses this label, if any
