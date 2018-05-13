# -*- config: utf-8 -*-

# counter for generating unique random fake values
RAND_COUNT = 0

# Labels which must start a basic block, because they're used in a JP/CALL
LABELS = {}  # Label -> LabelInfo object

JUMP_LABELS = set([])
MEMORY = []  # Instructions emitted by the backend

# PROC labels name space counter
PROC_COUNTER = 0

BLOCKS = []  # Memory blocks
