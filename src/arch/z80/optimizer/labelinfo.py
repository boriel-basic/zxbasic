# -*- coding: utf-8 -*-

from typing import TYPE_CHECKING
from . import common, errors

if TYPE_CHECKING:
    from .basicblock import BasicBlock


class LabelInfo(object):
    """Class describing label information"""

    def __init__(self, label, addr, basic_block=None, position=0):
        """Stores the label name, the address counter into memory (rather useless)
        and which basic block contains it.
        """
        self.label = label
        self.addr = addr
        self.basic_block = basic_block
        self.position = position  # Position within the block
        self.used_by: set[BasicBlock] = set()  # Which BB uses this label, if any

        if label in common.LABELS:
            raise errors.DuplicatedLabelError(label)
