# -*- coding: utf-8 -*-

import arch
import api.utils

from api.debug import __DEBUG__
from identityset import IdentitySet
from .memcell import MemCell
from .labelinfo import LabelInfo
from .helpers import ALL_REGS, END_PROGRAM_LABEL
from .common import LABELS, JUMP_LABELS
from .errors import OptimizerInvalidBasicBlockError
from .cpustate import CPUState
from ..peephole import engine
from ..peephole import evaluator

from . import helpers
from .. import backend


class BasicBlock(object):
    """ A Class describing a basic block
    """
    __UNIQUE_ID = 0

    def __init__(self, memory):
        """ Initializes the internal array of instructions.
        """
        self.mem = None
        self.next = None  # Which (if any) basic block follows this one in the code
        self.prev = None  # Which (if any) basic block precedes to this one in the code
        self.original_next = None  # Which block originally followed this one in the code, if any
        self.lock = False  # True if this block is being accessed by other subroutine
        self.comes_from = IdentitySet()  # A list/tuple containing possible jumps to this block
        self.goes_to = IdentitySet()  # A list/tuple of possible block to jump from here
        self.modified = False  # True if something has been changed during optimization
        self.calls = IdentitySet()
        self.label_goes = IdentitySet()
        self.ignored = False  # True if this block can be ignored (it's useless)
        self.id = BasicBlock.__UNIQUE_ID
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None
        BasicBlock.__UNIQUE_ID += 1
        self.code = memory

    def __len__(self):
        return len(self.mem)

    def __str__(self):
        return '\n'.join(x for x in self.code)

    def __repr__(self):
        return "<{}: id: {}, len: {}>".format(self.__class__.__name__, self.id, len(self))

    def __getitem__(self, key):
        return self.mem[key]

    def __setitem__(self, key, value):
        self.mem[key].asm = value
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None

    def pop(self, i):
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None
        return self.mem.pop(i)

    def insert(self, i, value):
        memcell = MemCell(value, i)
        self.mem.insert(i, memcell)
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None

    @property
    def code(self):
        return [x.code for x in self.mem]

    @code.setter
    def code(self, value):
        assert isinstance(value, (list, tuple))
        assert all(isinstance(x, str) for x in value)
        self.mem = [MemCell(asm, i) for i, asm in enumerate(value)]
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None

    @property
    def bytes(self):
        """ Returns length in bytes (number of bytes this block takes)
        """
        if self._bytes is not None:
            return self._bytes

        self._bytes = list(x.bytes for x in self.mem)
        return self._bytes

    @property
    def sizeof(self):
        """ Returns the size of this block in bytes once assembled
        """
        if self._sizeof:
            return self._sizeof

        self._sizeof = sum(len(x) for x in self.bytes)
        return self._sizeof

    @property
    def max_tstates(self):
        if self._max_tstates is not None:
            return self._max_tstates

        self._max_tstates = sum(x.max_tstates for x in self.mem)
        return self._max_tstates

    @property
    def labels(self):
        """ Returns a t-uple containing labels within this block
        """
        return [cell.inst for cell in self.mem if cell.is_label]

    @property
    def is_partitionable(self):
        """ Returns if this block can be partitions in 2 or more blocks,
        because if contains enders.
        """
        if len(self.mem) < 2:
            return False  # An atomic block

        if any(x.is_ender or x.code in backend.ASMS for x in self.mem[:]):
            return True

        for label in JUMP_LABELS:
            if LABELS[label].basic_block != self:
                continue

            for i in range(len(self)):
                if not self.mem[i].is_label:
                    return True  # An instruction? Should start with a Jump Label

                if self.mem[i].inst == label:
                    break  # found
            else:
                raise OptimizerInvalidBasicBlockError(self)  # Label is pointing to the wrong block? not found

        return False

    def update_labels(self):
        """ Update global labels table so they point to the current block
        """
        for l in self.labels:
            LABELS[l].basic_block = self

    def delete_from(self, basic_block):
        """ Removes the basic_block ptr from the list for "comes_from"
        if it exists. It also sets self.prev to None if it is basic_block.
        """
        if basic_block is None:
            return

        if self.lock:
            return

        self.lock = True

        if self.prev is basic_block:
            if self.prev.next is self:
                self.prev.next = None
            self.prev = None

        for i in range(len(self.comes_from)):
            if self.comes_from[i] is basic_block:
                self.comes_from.pop(i)
                break

        self.lock = False

    def delete_goes(self, basic_block):
        """ Removes the basic_block ptr from the list for "goes_to"
        if it exists. It also sets self.next to None if it is basic_block.
        """
        if basic_block is None:
            return

        if self.lock:
            return

        self.lock = True

        if self.next is basic_block:
            if self.next.prev is self:
                self.next.prev = None
            self.next = None

        for i in range(len(self.goes_to)):
            if self.goes_to[i] is basic_block:
                self.goes_to.pop(i)
                basic_block.delete_from(self)
                break

        self.lock = False

    def add_comes_from(self, basic_block):
        """ This simulates a set. Adds the basic_block to the comes_from
        list if not done already.
        """
        if basic_block is None:
            return

        if self.lock:
            return

        # Return if already added
        if basic_block in self.comes_from:
            return

        self.lock = True
        self.comes_from.add(basic_block)
        basic_block.add_goes_to(self)
        self.lock = False

    def add_goes_to(self, basic_block):
        """ This simulates a set. Adds the basic_block to the goes_to
        list if not done already.
        """
        if basic_block is None:
            return

        if self.lock:
            return

        if basic_block in self.goes_to:
            return

        self.lock = True
        self.goes_to.add(basic_block)
        basic_block.add_comes_from(self)
        self.lock = False

    def update_next_block(self):
        """ If the last instruction of this block is a JP, JR or RET (with no
        conditions) then the next and goes_to sets just contains a
        single block
        """
        last = self.mem[-1]
        if last.inst not in ('ret', 'jp', 'jr') or last.condition_flag is not None:
            return

        if last.inst == 'ret':
            if self.next is not None:
                self.next.delete_from(self)
                self.delete_goes(self.next)
            return

        if last.opers[0] not in LABELS.keys():
            __DEBUG__("INFO: %s is not defined. No optimization is done." % last.opers[0], 2)
            LABELS[last.opers[0]] = LabelInfo(last.opers[0], 0, DummyBasicBlock(ALL_REGS, ALL_REGS))

        n_block = LABELS[last.opers[0]].basic_block
        if self.next is n_block:
            return

        if self.next.prev == self:
            # The next basic block is not this one since it ends with a jump
            self.next.delete_from(self)
            self.delete_goes(self.next)

        self.next = n_block
        self.next.add_comes_from(self)
        self.add_goes_to(self.next)

    def update_used_by_list(self):
        """ Every label has a set containing
        which blocks jumps (jp, jr, call) if any.
        A block can "use" (call/jump) only another block
        and only one"""

        # Searches all labels and remove this block out
        # of their used_by set, since this might have changed
        for label in LABELS.values():
            label.used_by.remove(self)  # Delete this bblock

    def clean_up_goes_to(self):
        for x in self.goes_to:
            if x is not self.next:
                self.delete_goes(x)

    def clean_up_comes_from(self):
        for x in self.comes_from:
            if x is not self.prev:
                self.delete_from(x)

    def update_goes_and_comes(self):
        """ Once the block is a Basic one, check the last instruction and updates
        goes_to and comes_from set of the receivers.
        Note: jp, jr and ret are already done in update_next_block()
        """
        # Remove any block from the comes_from and goes_to list except the PREVIOUS and NEXT
        if not len(self):
            return

        if self.mem[-1].inst == 'ret':
            return  # subroutine returns are updated from CALLer blocks

        self.update_used_by_list()

        if not self.mem[-1].is_ender:
            return

        last = self.mem[-1]
        inst = last.inst
        oper = last.opers
        cond = last.condition_flag

        if oper and oper[0] not in LABELS.keys():
            __DEBUG__("INFO: %s is not defined. No optimization is done." % oper[0], 1)
            LABELS[oper[0]] = LabelInfo(oper[0], 0, DummyBasicBlock(ALL_REGS, ALL_REGS))

        if inst == 'djnz' or inst in ('jp', 'jr') and cond is not None:
            if oper[0] in LABELS:
                self.add_goes_to(LABELS[oper[0]].basic_block)

        elif inst in ('jp', 'jr') and cond is None:
            if oper[0] in LABELS:
                self.delete_goes(self.next)
                self.next = LABELS[oper[0]].basic_block
                self.add_goes_to(self.next)

        elif inst == 'call':
            LABELS[oper[0]].basic_block.add_comes_from(self)
            stack = [LABELS[oper[0]].basic_block]
            bbset = IdentitySet()

            while stack:
                bb = stack.pop(0)

                while bb is not None:
                    if bb in bbset:
                        break

                    bbset.add(bb)
                    if len(bb):
                        bb1 = bb[-1]
                        if bb1.inst == 'ret':
                            bb.add_goes_to(self.next)
                            if bb1.condition_flag is None:  # 'ret'
                                break

                        if bb1.inst in ('jp', 'jr') and bb1.condition_flag is not None:  # jp/jr nc/nz/.. LABEL
                            if bb1.opers[0] in LABELS:  # some labels does not exist (e.g. immediate numeric addresses)
                                stack += [LABELS[bb1.opers[0]].basic_block]

                    bb = bb.next  # next contiguous block

            if cond is None:
                self.calls.add(LABELS[oper[0]].basic_block)

    def is_used(self, regs, i, top=None):
        """ Checks whether any of the given regs are required from the given point
        to the end or not.
        """
        if i < 0:
            i = 0

        if self.lock:
            return True

        regs = api.utils.flatten_list([helpers.single_registers(x) for x in regs])  # make a copy
        if top is None:
            top = len(self)
        else:
            top -= 1

        for ii in range(i, top):
            for r in self.mem[ii].requires:
                if r in regs:
                    return True

            for r in self.mem[ii].destroys:
                if r in regs:
                    regs.remove(r)

            if not regs:
                return False

        self.lock = True
        result = self.goes_requires(regs)
        self.lock = False

        return result

    def safe_to_write(self, regs, i=0, end_=0):
        """ Given a list of registers (8 or 16 bits) returns a list of them
        that are safe to modify from the given index until the position given
        which, if omitted, defaults to the end of the block.
        :param regs: register or iterable of registers (8 or 16 bit one)
        :param i: initial position of the block to examine
        :param end_: final position to examine
        :returns: registers safe to write
        """
        if helpers.is_register(regs):
            regs = set(helpers.single_registers(regs))
        else:
            regs = set(helpers.single_registers(x) for x in regs)
        return not regs.intersection(self.requires(i, end_))

    def requires(self, i=0, end_=None):
        """ Returns a list of registers and variables this block requires.
        By default checks from the beginning (i = 0).
        :param i: initial position of the block to examine
        :param end_: final position to examine
        :returns: registers safe to write
        """
        if i < 0:
            i = 0
        end_ = len(self) if end_ is None or end_ > len(self) else end_
        regs = {'a', 'b', 'c', 'd', 'e', 'f', 'h', 'l', 'i', 'ixh', 'ixl', 'iyh', 'iyl', 'sp'}
        result = set()

        for ii in range(i, end_):
            for r in self.mem[ii].requires:
                r = r.lower()
                if r in regs:
                    result.add(r)
                    regs.remove(r)

            for r in self.mem[ii].destroys:
                r = r.lower()
                if r in regs:
                    regs.remove(r)

            if not regs:
                break

        return result

    def destroys(self, i=0):
        """ Returns a list of registers this block destroys
        By default checks from the beginning (i = 0).
        """
        regs = {'a', 'b', 'c', 'd', 'e', 'f', 'h', 'l', 'i', 'ixh', 'ixl', 'iyh', 'iyl', 'sp'}
        top = len(self)
        result = []

        for ii in range(i, top):
            for r in self.mem[ii].destroys:
                if r in regs:
                    result.append(r)
                    regs.remove(r)

            if not regs:
                break

        return result

    def swap(self, a, b):
        """ Swaps mem positions a and b
        """
        self.mem[a], self.mem[b] = self.mem[b], self.mem[a]

    def goes_requires(self, regs):
        """ Returns whether any of the goes_to block requires any of
        the given registers.
        """
        if len(self) and self.mem[-1].inst == 'call' and self.mem[-1].condition_flag is None:
            for block in self.calls:
                if block.is_used(regs, 0):
                    return True

                d = block.destroys()
                if not len([x for x in regs if x not in d]):
                    return False  # If all registers are destroyed then they're not used

        for block in self.goes_to:
            if block.is_used(regs, 0):
                return True

        return False

    def get_label_idx(self, label):
        """ Returns the index of a label.
        Returns None if not found.
        """
        for i in range(len(self)):
            if self.mem[i].is_label and self.mem[i].inst == label:
                return i

        return None

    def get_first_non_label_instruction(self):
        """ Returns the memcell of the given block, which is
        not a LABEL.
        """
        for i in range(len(self)):
            if not self.mem[i].is_label:
                return self.mem[i]

        return None

    def optimize(self):
        """ Tries to detect peep-hole patterns in this basic block
        and remove them.
        """
        filtered_patterns_list = [p for p in engine.PATTERNS if p.level >= 3]
        changed = True
        code = self.code
        cpu = CPUState()
        old_unary = dict(evaluator.Evaluator.UNARY)
        evaluator.Evaluator.UNARY['GVAL'] = lambda x: cpu.get(x)

        while changed:
            changed = False
            cpu.reset()

            for i, asm_line in enumerate(code):
                for p in filtered_patterns_list:
                    match = p.patt.match(code[i:])
                    if match is None:  # HINT: {} is also a valid match
                        continue

                    for var, defline in p.defines:
                        match[var] = defline.expr.eval(match)

                    evaluator.Evaluator.UNARY['IS_REQUIRED'] = lambda x: self.is_used([x], i + len(p.patt))
                    if not p.cond.eval(match):
                        continue

                    # all patterns applied successfully. Apply this pattern
                    new_code = list(code)
                    new_code[i: i + len(p.patt)] = p.template.filter(match)
                    api.errmsg.info('pattern applied [{}:{}]'.format("%03i" % p.flag, p.fname))
                    changed = new_code != code
                    if changed:
                        code = new_code
                        self.code = new_code
                        break

                if changed:
                    break

                cpu.execute(asm_line)

        evaluator.Evaluator.UNARY.update(old_unary)  # restore old copy


class DummyBasicBlock(BasicBlock):
    """ A dummy basic block with some basic information
    about what registers uses an destroys
    """

    def __init__(self, destroys, requires):
        BasicBlock.__init__(self, [])
        self.__destroys = [x for x in destroys]
        self.__requires = [x for x in requires]

    def destroys(self):
        return [x for x in self.__destroys]

    def requires(self):
        return [x for x in self.__requires]

    def is_used(self, regs, i, top=None):
        return len([x for x in regs if x in self.__requires]) > 0


def block_partition(block, i):
    """ Returns two blocks, as a result of partitioning the given one at
    i-th instruction.
    """
    i += 1
    new_block = BasicBlock([])
    new_block.mem = block.mem[i:]
    block.mem = block.mem[:i]

    for label, lbl_info in LABELS.items():
        if lbl_info.basic_block != block or lbl_info.position < len(block):
            continue

        lbl_info.basic_block = new_block
        lbl_info.position -= len(block)

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


def get_basic_blocks(block):
    """ If a block is not partitionable, returns a list with the same block.
    Otherwise, returns a list with the resulting blocks, recursively.
    """
    result = []
    EDP = END_PROGRAM_LABEL + ':'

    new_block = block
    while new_block:
        block = new_block
        new_block = None

        for i in range(len(block) - 1):
            if i and block.mem[i].code == EDP:  # END_PROGRAM label always starts a basic block
                block, new_block = block_partition(block, i - 1)
                LABELS[END_PROGRAM_LABEL].basic_block = new_block
                break

            if block.mem[i].is_ender:
                block, new_block = block_partition(block, i)
                op = block.mem[i].opers

                for l in op:
                    if l in LABELS.keys():
                        JUMP_LABELS.add(l)
                        block.label_goes.append(l)
                break

            if block.mem[i].code in arch.zx48k.backend.ASMS:
                block, new_block = block_partition(block, max(0, i - 1))
                break

        result.append(block)

    for label in JUMP_LABELS:
        blk = LABELS[label].basic_block
        if isinstance(blk, DummyBasicBlock):
            continue

        must_partition = False
        # This label must point to the beginning of blk, just before the code
        # Otherwise we must partition it (must_partition = True)
        for i in range(len(blk)):
            cell = blk.mem[i]
            if cell.inst == label:
                break  # already starts with this label

            if cell.is_label:
                continue  # It's another label

            if cell.is_ender:
                raise OptimizerInvalidBasicBlockError(blk)

            must_partition = True
        else:
            __DEBUG__("Label {} not found in BasicBlock {}".format(label, blk.id))
            continue

        if must_partition:
            j = result.index(blk)
            block_, new_block_ = block_partition(blk, i - 1)
            LABELS[label].basic_block = new_block_
            result.pop(j)
            result.insert(j, block_)
            result.insert(j + 1, new_block_)

    return result
