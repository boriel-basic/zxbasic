# -*- coding: utf-8 -*-

from src.api.utils import flatten_list
from ..peephole import engine

from .patterns import RE_PRAGMA, RE_LABEL
from .common import LABELS, JUMP_LABELS, MEMORY
from .helpers import END_PROGRAM_LABEL, ALL_REGS
from .basicblock import DummyBasicBlock
from . import basicblock
from .labelinfo import LabelInfo
from src.api.config import OPTIONS
from src.api.debug import __DEBUG__


def init():
    global LABELS
    global JUMP_LABELS

    LABELS.clear()
    JUMP_LABELS.clear()

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


def get_labels(basic_block):
    """ Traverses memory, to annotate all the labels in the global
    LABELS table
    """
    for i, cell in enumerate(basic_block):
        if cell.is_label:
            label = cell.inst
            LABELS[label] = LabelInfo(label, cell.addr, basic_block, i)  # Stores it globally


def initialize_memory(basic_block):
    """ Initializes global memory array with the one in the main (initial) basic_block
    """
    global MEMORY

    init()
    MEMORY = basic_block.mem
    get_labels(basic_block)


def optimize(initial_memory):
    """ This will remove useless instructions
    """
    global BLOCKS
    global PROC_COUNTER

    del MEMORY[:]
    PROC_COUNTER = 0

    cleanupmem(initial_memory)
    if OPTIONS.optimization <= 2:  # if -O2 or lower, do nothing and return
        return '\n'.join(x for x in initial_memory if not RE_PRAGMA.match(x))

    basicblock.BasicBlock.clean_asm_args = OPTIONS.optimization > 3
    bb = basicblock.BasicBlock(initial_memory)
    cleanup_local_labels(bb)
    initialize_memory(bb)

    BLOCKS = basic_blocks = basicblock.get_basic_blocks(bb)  # 1st partition the Basic Blocks

    for b in basic_blocks:
        __DEBUG__('--- BASIC BLOCK: {} ---'.format(b.id), 1)
        __DEBUG__('Code:\n' + '\n'.join('    {}'.format(x) for x in b.code), 1)
        __DEBUG__('Requires: {}'.format(b.requires()), 1)
        __DEBUG__('Destroys: {}'.format(b.destroys()), 1)
        __DEBUG__('Label goes: {}'.format(b.label_goes), 1)
        __DEBUG__('Comes from: {}'.format([x.id for x in b.comes_from]), 1)
        __DEBUG__('Goes to: {}'.format([x.id for x in b.goes_to]), 1)
        __DEBUG__('Next: {}'.format(b.next.id if b.next is not None else None), 1)
        __DEBUG__('Size: {}  Time: {}'.format(b.sizeof, b.max_tstates), 1)
        __DEBUG__('--- END ---', 1)

    LABELS['*START*'].basic_block.add_goes_to(basic_blocks[0])
    LABELS['*START*'].basic_block.next = basic_blocks[0]

    basic_blocks[0].prev = LABELS['*START*'].basic_block
    LABELS[END_PROGRAM_LABEL].basic_block.add_goes_to(LABELS['*__END_PROGRAM*'].basic_block)

    # In O3 we simplify the graph by reducing jumps over jumps
    for label in JUMP_LABELS:
        block = LABELS[label].basic_block
        if isinstance(block, DummyBasicBlock):
            continue

        # The instruction that starts this block must be one of jr / jp
        first = block.get_next_exec_instruction()
        if first is None or first.inst not in ('jp', 'jr'):
            continue

        for blk in list(LABELS[label].used_by):
            if not first.condition_flag or blk[-1].condition_flag == first.condition_flag:
                new_label = first.opers[0]
                blk[-1].asm = blk[-1].code.replace(label, new_label)
                block.delete_comes_from(blk)
                LABELS[label].used_by.remove(blk)
                LABELS[new_label].used_by.add(blk)
                blk.add_goes_to(LABELS[new_label].basic_block)

    for x in basic_blocks:
        x.compute_cpu_state()

    filtered_patterns_list = [p for p in engine.PATTERNS if OPTIONS.optimization >= p.level >= 3]
    for x in basic_blocks:
        x.optimize(filtered_patterns_list)

    for x in basic_blocks:
        if x.comes_from == [] and len([y for y in JUMP_LABELS if x is LABELS[y].basic_block]):
            x.ignored = True

    return '\n'.join([y for y in flatten_list([x.code for x in basic_blocks if not x.ignored])
                      if not RE_PRAGMA.match(y)])
