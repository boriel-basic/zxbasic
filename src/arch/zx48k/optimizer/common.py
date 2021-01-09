# -*- config: utf-8 -*-

from typing import Dict

from . import labelinfo

# counter for generating unique random fake values
RAND_COUNT = 0

# Labels which must start a basic block, because they're used in a JP/CALL
LABELS: Dict[str, labelinfo.LabelInfo] = {}  # Label -> LabelInfo object

JUMP_LABELS = set([])
MEMORY = []  # Instructions emitted by the backend

# PROC labels name space counter
PROC_COUNTER = 0

BLOCKS = []  # Memory blocks
