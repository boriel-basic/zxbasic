from src.api.debug import __DEBUG__

from .basicblock import BasicBlock, DummyBasicBlock
from .helpers import ALL_REGS
from .labelinfo import LabelInfo
from .labels_dict import LabelsDict

__all__ = ("get_basic_blocks",)


def _split_block(block: BasicBlock, start_of_new_block: int, labels: LabelsDict) -> tuple[BasicBlock, BasicBlock]:
    assert 0 <= start_of_new_block < len(block), f"Invalid split pos: {start_of_new_block}"
    new_block = BasicBlock([], block.optimizer)
    new_block.mem = block.mem[start_of_new_block:]
    block.mem = block.mem[:start_of_new_block]

    new_block.next = block.next
    block.next = new_block
    new_block.prev = block

    if new_block.next is not None:
        new_block.next.prev = new_block

    for blk in list(block.goes_to):
        block.delete_goes_to(blk)
        new_block.add_goes_to(blk)

    block.add_goes_to(new_block)

    for i, mem in enumerate(new_block):
        if mem.is_label and mem.inst in labels:
            labels[mem.inst].basic_block = new_block
            labels[mem.inst].position = i

    if block[-1].is_ender:
        if not block[-1].condition_flag:  # If it's an unconditional jp, jr, call, ret
            block.delete_goes_to(block.next)

    return block, new_block


def _compute_calls(
    basic_blocks: list[BasicBlock],
    labels: LabelsDict,
    jump_labels: set[str],
) -> None:
    calling_blocks: dict[BasicBlock, BasicBlock] = {}

    # Compute which blocks use jump labels
    for bb in basic_blocks:
        if bb[-1].is_ender and (op := bb[-1].branch_arg) in labels:
            labels[op].used_by.add(bb)

    # For these blocks, add the referenced block in the goes_to
    for label in jump_labels:
        for bb in labels[label].used_by:
            bb.add_goes_to(labels[label].basic_block)

    # Annotate which blocks uses call (which should be the last instruction)
    for bb in basic_blocks:
        if bb[-1].inst != "call":
            continue

        op = bb[-1].branch_arg
        if op in labels:
            labels[op].basic_block.called_by.add(bb)
            calling_blocks[bb] = labels[op].basic_block

    # For the annotated blocks, trace their goes_to, and their goes_to from
    # their goes_to and so on, until ret (unconditional or not) is found, and
    # save that block in a set for later
    visited: set[tuple[BasicBlock, BasicBlock]] = set()
    pending: set[tuple[BasicBlock, BasicBlock]] = set(calling_blocks.items())

    while pending:
        caller, bb = pending.pop()
        if (caller, bb) in visited:
            continue

        visited.add((caller, bb))

        if not bb[-1].is_ender:  # if it does not branch, search in the next block
            pending.add((caller, bb.next))
            continue

        if bb[-1].inst in {"ret", "reti", "retn"}:
            if bb[-1].condition_flag:
                pending.add((caller, bb.next))

            bb.add_goes_to(caller.next)
            continue

        if bb[-1].inst in {"call", "rst"}:  # A call from this block
            if bb[-1].condition_flag:  # if it has conditions, it can return from the next block
                pending.add((caller, bb.next))


def _get_jump_labels(main_basic_block: BasicBlock, labels: LabelsDict) -> set[str]:
    """Given the main basic block (which contain the entire program), populate
    the global JUMP_LABEL set with LABELS used by CALL, JR, JP (i.e JP LABEL0)
    Also updates the global LABELS index with the pertinent information.

    Any BasicBlock containing a JUMP_LABEL in any position which is not the initial
    one (0 position) must be split at that point into two basic blocks.
    """
    jump_labels: set[str] = set()

    for i, mem in enumerate(main_basic_block):
        if mem.is_label:
            labels.pop(mem.inst)
            labels[mem.inst] = LabelInfo(
                label=mem.inst,
                addr=i,
                basic_block=main_basic_block,
                position=i,  # Unknown yet
            )
            continue

        if not mem.is_ender:
            continue

        lbl = mem.branch_arg
        if lbl is None:
            continue

        jump_labels.add(lbl)

        if lbl not in labels:
            __DEBUG__(f"INFO: {lbl} is not defined. No optimization is done.", 2)
            labels[lbl] = LabelInfo(lbl, 0, DummyBasicBlock(ALL_REGS, ALL_REGS, main_basic_block.optimizer))

    return jump_labels


def get_basic_blocks(block: BasicBlock) -> list[BasicBlock]:
    """If a block is not partitionable, returns a list with the same block.
    Otherwise, returns a list with the resulting blocks.
    """
    result: list[BasicBlock] = [block]
    block.jump_labels.clear()
    block.jump_labels.update(_get_jump_labels(block, block.opt_labels))

    # Split basic blocks per label or branch instruction
    split_pos = block.get_first_partition_idx()
    while split_pos is not None:
        _, block = _split_block(block, split_pos, block.opt_labels)
        result.append(block)
        split_pos = block.get_first_partition_idx()

    _compute_calls(result, block.opt_labels, block.jump_labels)

    return result
