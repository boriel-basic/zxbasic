#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:ai:sw=4:

# -----------------------------------------------------------------------------
# An peephole optimizer using some simple rules
# -----------------------------------------------------------------------------

import re
import sys

from api.errors import Error
from api.config import OPTIONS
from api.debug import __DEBUG__
from arch.zx48k.asm import Asm
from identityset import IdentitySet
import asmlex
import arch.zx48k.backend
from collections import defaultdict

UNKNOWN_PREFIX = '*UNKNOWN_'
END_PROGRAM_LABEL = '__END_PROGRAM'  # Label for end program

sys.setrecursionlimit(10000)
# Labels which must start a basic block, because they're used in a JP/CALL
LABELS = {}  # Label -> LabelInfo object

JUMP_LABELS = set([])
MEMORY = []  # Instructions emitted by the backend

# Instructions that ends a BLOCK
BLOCK_ENDERS = ('jr', 'jp', 'call', 'ret', 'reti', 'retn', 'djnz', 'rst')

# PROC labels name space counter
PROC_COUNTER = 0

BLOCKS = []  # Memory blocks


# Enabled Optimizations (this is useful for debugging)
OPT00 = True
OPT01 = True
OPT02 = True
OPT03 = True
OPT04 = True
OPT05 = True
OPT06 = True
OPT07 = True
OPT08 = True
OPT09 = True
OPT10 = True
OPT11 = True
OPT12 = True
OPT13 = True
OPT14 = True
OPT15 = True
OPT16 = True
OPT17 = True
OPT18 = True
OPT19 = True
OPT20 = True
OPT21 = True
OPT22 = True
OPT23 = True
OPT24 = True
OPT25 = True
OPT26 = True
OPT27 = True


RAND_COUNT = 0


def new_tmp_val():
    global RAND_COUNT
    RAND_COUNT += 1
    return '{0}{1}'.format(UNKNOWN_PREFIX, RAND_COUNT)


def is_register(x):
    """ True if x is a register.
    """
    if not isinstance(x, str):
        return False

    return x.lower() in REGS_OPER_SET


def is_number(x):
    if x is None:
        return False

    if isinstance(x, (int, float)):
        return True

    if isinstance(x, str) and x[0] == '(' and x[-1] == ')':
        return False

    try:
        tmp = eval(x, {}, {})
        if isinstance(tmp, (int, float)):
            return True
    except:
        pass

    return RE_NUMBER.match(str(x)) is not None


def is_unknown(x):
    return x is None or x.startswith(UNKNOWN_PREFIX)


def valnum(x):
    if not is_number(x):
        return None

    x = str(x)

    if x[0] == '%':
        return int(x[1:], 2)

    if x[-1] in ('b', 'B'):
        return int(x[:-1], 2)

    if x[0] == '$':
        return int(x[1:], 16)

    if x[-1] in ('h', 'H'):
        return int(x[:-1], 16)

    return int(eval(x, {}, {}))



# ------------------------------------------------------------------------------- #



def block_partition(block, i):
    """ Returns two blocks, as a result of partitioning the given one at
    i-th instruction.
    """
    i += 1
    new_block = BasicBlock([x.asm for x in block.asm[i:]])
    block.mem = block.mem[:i]
    block.asm = block.asm[:i]
    block.update_labels()
    new_block.update_labels()

    new_block.goes_to = block.goes_to
    block.goes_to = IdentitySet()

    new_block.label_goes = block.label_goes
    block.label_goes = []

    new_block.next = new_block.original_next = block.original_next
    new_block.prev = block
    new_block.add_comes_from(block)

    if new_block.next is not None:
        new_block.next.prev = new_block
        new_block.next.add_comes_from(new_block)
        new_block.next.delete_from(block)

    block.next = block.original_next = new_block
    block.update_next_block()
    block.add_goes_to(new_block)

    return block, new_block


def partition_block(block):
    """ If a block is not partitionable, returns a list with the same block.
    Otherwise, returns a list with the resulting blocks, recursively.
    """
    result = [block]

    if not block.is_partitionable:
        return result

    EDP = END_PROGRAM_LABEL + ':'

    for i in range(len(block) - 1):
        if i and block.asm[i] == EDP:  # END_PROGRAM label always starts a basic block
            block, new_block = block_partition(block, i - 1)
            LABELS[END_PROGRAM_LABEL].basic_block = new_block
            result.extend(partition_block(new_block))
            return result

        if block.mem[i].is_ender:
            block, new_block = block_partition(block, i)
            result.extend(partition_block(new_block))
            op = block.mem[i].opers

            for l in op:
                if l in LABELS.keys():
                    JUMP_LABELS.add(l)
                    block.label_goes += [l]
            return result

        if block.asm[i] in arch.zx48k.backend.ASMS:
            if i > 0:
                block, new_block = block_partition(block, i - 1)
                result.extend(partition_block(new_block))
                return result

            block, new_block = block_partition(block, i)
            result.extend(partition_block(new_block))
            return result

    for label in JUMP_LABELS:
        must_partition = False
        if LABELS[label].basic_block is block:
            for i in range(len(block)):
                cell = block.mem[i]
                if cell.inst == label:
                    break

                if cell.is_label:
                    continue

                if cell.is_ender:
                    continue

                must_partition = True

            if must_partition:
                block, new_block = block_partition(block, i - 1)
                LABELS[label].basic_block = new_block
                result.extend(partition_block(new_block))
                return result

    return result


# ---------------------------------------------------------------------------------------

def get_basic_blocks(bb):
    bb = partition_block(bb)

    if len(bb) == 1:
        return bb

    for i in range(len(bb)):
        bb[i] = get_basic_blocks(bb[i])

    bb = flatten_list(bb)
    return bb


def get_labels(MEMORY, basic_block):
    """ Traverses memory, to annotate all the labels in the global
    LABELS table
    """
    for cell in MEMORY:
        if cell.is_label:
            label = cell.inst
            LABELS[label] = LabelInfo(label, cell.addr, basic_block)  # Stores it globally


def initialize_memory(basic_block):
    """ Initializes global memory array with the given one
    """
    global MEMORY

    MEMORY = basic_block.mem
    get_labels(MEMORY, basic_block)
    basic_block.mem = MEMORY


def optimize_init():
    global LABELS

    LABELS['*START*'] = LabelInfo('*START*', 0, DummyBasicBlock(ALL_REGS, ALL_REGS))  # Special START BLOCK
    LABELS['*__END_PROGRAM*'] = LabelInfo('__END_PROGRAM', 0, DummyBasicBlock(ALL_REGS, list('bc')))

    # SOME Global modules initialization
    LABELS['__ADDF'] = LabelInfo('__ADDF', 0, DummyBasicBlock(ALL_REGS, list('aedbc')))
    LABELS['__SUBF'] = LabelInfo('__SUBF', 0, DummyBasicBlock(ALL_REGS, list('aedbc')))
    LABELS['__DIVF'] = LabelInfo('__DIVF', 0, DummyBasicBlock(ALL_REGS, list('aedbc')))
    LABELS['__MULF'] = LabelInfo('__MULF', 0, DummyBasicBlock(ALL_REGS, list('aedbc')))
    LABELS['__GEF'] = LabelInfo('__GEF', 0, DummyBasicBlock(ALL_REGS, list('aedbc')))
    LABELS['__GTF'] = LabelInfo('__GTF', 0, DummyBasicBlock(ALL_REGS, list('aedbc')))
    LABELS['__EQF'] = LabelInfo('__EQF', 0, DummyBasicBlock(ALL_REGS, list('aedbc')))
    LABELS['__STOREF'] = LabelInfo('__STOREF', 0, DummyBasicBlock(ALL_REGS, list('hlaedbc')))
    LABELS['PRINT_AT'] = LabelInfo('PRINT_AT', 0, DummyBasicBlock(ALL_REGS, list('a')))
    LABELS['INK'] = LabelInfo('INK', 0, DummyBasicBlock(ALL_REGS, list('a')))
    LABELS['INK_TMP'] = LabelInfo('INK_TMP', 0, DummyBasicBlock(ALL_REGS, list('a')))
    LABELS['PAPER'] = LabelInfo('PAPER', 0, DummyBasicBlock(ALL_REGS, list('a')))
    LABELS['PAPER_TMP'] = LabelInfo('PAPER_TMP', 0, DummyBasicBlock(ALL_REGS, list('a')))
    LABELS['RND'] = LabelInfo('RND', 0, DummyBasicBlock(ALL_REGS, []))
    LABELS['INKEY'] = LabelInfo('INKEY', 0, DummyBasicBlock(ALL_REGS, []))
    LABELS['PLOT'] = LabelInfo('PLOT', 0, DummyBasicBlock(ALL_REGS, ['a']))
    LABELS['DRAW'] = LabelInfo('DRAW', 0, DummyBasicBlock(ALL_REGS, ['h', 'l']))
    LABELS['DRAW3'] = LabelInfo('DRAW3', 0, DummyBasicBlock(ALL_REGS, list('abcde')))
    LABELS['__ARRAY'] = LabelInfo('__ARRAY', 0, DummyBasicBlock(ALL_REGS, ['h', 'l']))
    LABELS['__MEMCPY'] = LabelInfo('__MEMCPY', 0, DummyBasicBlock(list('bcdefhl'), list('bcdehl')))
    LABELS['__PLOADF'] = LabelInfo('__PLOADF', 0, DummyBasicBlock(ALL_REGS, ALL_REGS))  # Special START BLOCK
    LABELS['__PSTOREF'] = LabelInfo('__PSTOREF', 0, DummyBasicBlock(ALL_REGS, ALL_REGS))  # Special START BLOCK


def cleanupmem(initial_memory):
    """ Cleans up initial memory. Each label must be
    ALONE. Each instruction must have an space, etc...
    """
    i = 0
    while i < len(initial_memory):
        tmp = initial_memory[i]
        match = RE_LABEL.match(tmp)
        if not match:
            i += 1
            continue

        if tmp.rstrip() == match.group():
            i += 1
            continue

        initial_memory[i] = tmp[match.end():]
        initial_memory.insert(i, match.group())
        i += 1


def cleanup_local_labels(block):
    """ Traverses memory, to make any local label a unique
    global one. At this point there's only a single code
    block
    """
    global PROC_COUNTER

    stack = [[]]
    hashes = [{}]
    stackprc = [PROC_COUNTER]
    used = [{}]  # List of hashes of unresolved labels per scope

    MEMORY = block.mem

    for cell in MEMORY:
        if cell.inst.upper() == 'PROC':
            stack += [[]]
            hashes += [{}]
            stackprc += [PROC_COUNTER]
            used += [{}]
            PROC_COUNTER += 1
            continue

        if cell.inst.upper() == 'ENDP':
            if len(stack) > 1:  # There might be unbalanced stack due to syntax errors
                for label in used[-1].keys():
                    if label in stack[-1]:
                        newlabel = hashes[-1][label]
                        for cell in used[-1][label]:
                            cell.replace_label(label, newlabel)

                stack.pop()
                hashes.pop()
                stackprc.pop()
                used.pop()
            continue

        tmp = cell.asm.asm
        if tmp.upper()[:5] == 'LOCAL':
            tmp = tmp[5:].split(',')
            for lbl in tmp:
                lbl = lbl.strip()
                if lbl in stack[-1]:
                    continue
                stack[-1] += [lbl]
                hashes[-1][lbl] = 'PROC%i.' % stackprc[-1] + lbl
                if used[-1].get(lbl, None) is None:
                    used[-1][lbl] = []

            cell.asm = ';' + cell.asm  # Remove it
            continue

        if cell.is_label:
            label = cell.inst
            for i in range(len(stack) - 1, -1, -1):
                if label in stack[i]:
                    label = hashes[i][label]
                    cell.asm = label + ':'
                    break
            continue

        for label in cell.used_labels:
            labelUsed = False
            for i in range(len(stack) - 1, -1, -1):
                if label in stack[i]:
                    newlabel = hashes[i][label]
                    cell.replace_label(label, newlabel)
                    labelUsed = True
                    break

            if not labelUsed:
                if used[-1].get(label, None) is None:
                    used[-1][label] = []

                used[-1][label] += [cell]

    for i in range(len(MEMORY) - 1, -1, -1):
        if MEMORY[i].asm.asm[0] == ';':
            MEMORY.pop(i)

    block.mem = MEMORY
    block.asm = [x.asm for x in MEMORY if len(x.asm)]


def optimize(initial_memory):
    """ This will remove useless instructions
    """
    global BLOCKS
    global PROC_COUNTER

    LABELS.clear()
    JUMP_LABELS.clear()
    del MEMORY[:]
    PROC_COUNTER = 0

    cleanupmem(initial_memory)
    if OPTIONS.optimization.value <= 2:
        return '\n'.join(x for x in initial_memory if not RE_PRAGMA.match(x))

    optimize_init()
    bb = BasicBlock(initial_memory)
    cleanup_local_labels(bb)
    initialize_memory(bb)

    BLOCKS = basic_blocks = get_basic_blocks(bb)  # 1st partition the Basic Blocks

    for x in basic_blocks:
        x.clean_up_comes_from()
        x.clean_up_goes_to()

    for x in basic_blocks:
        x.update_goes_and_comes()

    LABELS['*START*'].basic_block.add_goes_to(basic_blocks[0])
    LABELS['*START*'].basic_block.next = basic_blocks[0]

    basic_blocks[0].prev = LABELS['*START*'].basic_block
    LABELS[END_PROGRAM_LABEL].basic_block.add_goes_to(LABELS['*__END_PROGRAM*'].basic_block)

    # for x in basic_blocks:
    #     x.optimize()

    for x in basic_blocks:
        if x.comes_from == [] and len([y for y in JUMP_LABELS if x is LABELS[y].basic_block]):
            x.ignored = True

    return '\n'.join([y.asm for y in flatten_list([x.asm for x in basic_blocks if not x.ignored])
                      if not RE_PRAGMA.match(y.asm)])
