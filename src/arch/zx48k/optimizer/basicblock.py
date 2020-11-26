# -*- coding: utf-8 -*-

import src.api.utils
import src.api.config

from src.api.debug import __DEBUG__
from src.api.identityset import IdentitySet

from .memcell import MemCell
from .labelinfo import LabelInfo
from .helpers import ALL_REGS, END_PROGRAM_LABEL
from .common import LABELS, JUMP_LABELS
from .errors import OptimizerInvalidBasicBlockError, OptimizerError
from .cpustate import CPUState
from .patterns import RE_ID_OR_NUMBER

from ..peephole import evaluator

from . import helpers
from .. import backend


class BasicBlock(object):
    """ A Class describing a basic block
    """
    __UNIQUE_ID = 0
    clean_asm_args = False

    def __init__(self, memory):
        """ Initializes the internal array of instructions.
        """
        self.mem = None
        self.next = None  # Which (if any) basic block follows this one in memory
        self.prev = None  # Which (if any) basic block precedes to this one in the code
        self.lock = False  # True if this block is being accessed by other subroutine
        self.comes_from = IdentitySet()  # A list/tuple containing possible jumps to this block
        self.goes_to = IdentitySet()  # A list/tuple of possible block to jump from here
        self.modified = False  # True if something has been changed during optimization
        self.calls = IdentitySet()
        self.label_goes = []
        self.ignored = False  # True if this block can be ignored (it's useless)
        self.id = BasicBlock.__UNIQUE_ID
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None
        self.optimized = False  # True if this block was already optimized
        BasicBlock.__UNIQUE_ID += 1
        self.code = memory
        self.cpu = CPUState()

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
        if self.clean_asm_args:
            self.mem = [MemCell(helpers.simplify_asm_args(asm), i) for i, asm in enumerate(value)]
        else:
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

    def delete_comes_from(self, basic_block):
        """ Removes the basic_block ptr from the list for "comes_from"
        if it exists. It also sets self.prev to None if it is basic_block.
        """
        if basic_block is None:
            return

        if self.lock:
            return

        self.lock = True

        for i in range(len(self.comes_from)):
            if self.comes_from[i] is basic_block:
                self.comes_from.pop(i)
                break

        self.lock = False

    def delete_goes_to(self, basic_block):
        """ Removes the basic_block ptr from the list for "goes_to"
        if it exists. It also sets self.next to None if it is basic_block.
        """
        if basic_block is None:
            return

        if self.lock:
            return

        self.lock = True

        for i in range(len(self.goes_to)):
            if self.goes_to[i] is basic_block:
                self.goes_to.pop(i)
                basic_block.delete_comes_from(self)
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
        conditions) then goes_to set contains just a
        single block
        """
        last = self.mem[-1]
        if last.inst not in {'djnz', 'jp', 'jr', 'call', 'ret', 'reti', 'retn', 'rst'}:
            return

        if last.inst in {'reti', 'retn'}:
            if self.next is not None:
                self.next.delete_comes_from(self)
            return

        if self.next is not None and last.condition_flag is None:  # jp NNN, call NNN, rst, jr NNNN, ret
            self.next.delete_comes_from(self)

        if last.inst == 'ret':
            return

        if last.opers[0] not in LABELS.keys():
            __DEBUG__("INFO: %s is not defined. No optimization is done." % last.opers[0], 2)
            LABELS[last.opers[0]] = LabelInfo(last.opers[0], 0, DummyBasicBlock(ALL_REGS, ALL_REGS))

        n_block = LABELS[last.opers[0]].basic_block
        self.add_goes_to(n_block)

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
                self.delete_goes_to(x)

    def clean_up_comes_from(self):
        for x in self.comes_from:
            if x is not self.prev:
                self.delete_comes_from(x)

    def update_goes_and_comes(self):
        """ Once the block is a Basic one, check the last instruction and updates
        goes_to and comes_from set of the receivers.
        Note: jp, jr and ret are already done in update_next_block()
        """
        if not len(self):
            return

        last = self.mem[-1]
        inst = last.inst
        oper = last.opers
        cond = last.condition_flag

        if not last.is_ender:
            return

        if cond is None:
            self.delete_goes_to(self.next)

        if last.inst in {'ret', 'reti', 'retn'} and cond is None:
            return  # subroutine returns are updated from CALLer blocks

        if oper and oper[0]:
            if oper[0] not in LABELS:
                __DEBUG__("INFO: %s is not defined. No optimization is done." % oper[0], 1)
                LABELS[oper[0]] = LabelInfo(oper[0], 0, DummyBasicBlock(ALL_REGS, ALL_REGS))

            LABELS[oper[0]].used_by.add(self)
            self.add_goes_to(LABELS[oper[0]].basic_block)

        if inst in {'djnz', 'jp', 'jr'}:
            return

        assert inst in ('call', 'rst')

        if self.next is None:
            raise OptimizerError("Unexpected NULL next block")

        final_blk = self.next  # The block all the final returns should go to
        stack = [LABELS[oper[0]].basic_block]
        bbset = IdentitySet()

        while stack:
            bb = stack.pop(0)
            while True:
                if bb is None:
                    bb = DummyBasicBlock(ALL_REGS, ALL_REGS)

                if bb in bbset:
                    break

                bbset.add(bb)

                if isinstance(bb, DummyBasicBlock):
                    bb.add_goes_to(final_blk)
                    break

                if bb:
                    bb1 = bb[-1]
                    if bb1.inst in {'ret', 'reti', 'retn'}:
                        bb.add_goes_to(final_blk)
                        if bb1.condition_flag is None:  # 'ret'
                            break
                    elif bb1.inst in ('jp', 'jr') and bb1.condition_flag is not None:  # jp/jr nc/nz/.. LABEL
                        if bb1.opers[0] in LABELS:  # some labels does not exist (e.g. immediate numeric addresses)
                            stack.append(LABELS[bb1.opers[0]].basic_block)
                        else:
                            raise OptimizerError("Unknown block label '{}'".format(bb1.opers[0]))

                bb = bb.next  # next contiguous block

    def is_used(self, regs, i, top=None):
        """ Checks whether any of the given regs are required from the given point
        to the end or not.
        """
        if i < 0:
            i = 0

        if self.lock:
            return True

        if top is None:
            top = len(self)
        else:
            top -= 1

        if regs and regs[0][0] == '(' and regs[0][-1] == ')':  # A memory address
            r16 = helpers.single_registers(regs[0][1:-1])\
                if helpers.is_16bit_oper_register(regs[0][1:-1]) else []
            ix = helpers.single_registers(helpers.idx_args(regs[0][1:-1])[0]) \
                if helpers.idx_args(regs[0][1:-1]) else []

            rr = set(r16 + ix)
            mem_vars = set([] if rr else RE_ID_OR_NUMBER.findall(regs[0]))

            for mem in self[i:top]:  # For memory accesses only mark as NOT uses if it's overwritten
                if mem.inst == 'ld' and mem.opers[0] == regs[0]:
                    return False

                if mem.opers and mem.opers[-1] == regs[0]:
                    return True

                if rr and any(_ in r16 for _ in mem.destroys):  # (hl) :: inc hl / (ix + n) :: inc ix
                    return True

                if mem.opers and mem_vars.intersection(RE_ID_OR_NUMBER.findall(mem.opers[-1])):
                    return True

            return True

        regs = src.api.utils.flatten_list([helpers.single_registers(x) for x in regs])  # make a copy
        for ii in range(i, top):
            if any(r in regs for r in self.mem[ii].requires):
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
        for mem in self:
            if not mem.is_label:
                return mem

        return None

    def get_next_exec_instruction(self):
        """ Return the first non label instruction to be executed, either
        in this block or in the following one. If there are more than one, return None.
        Also returns None if there is no instruction to be executed.
        """
        result = self.get_first_non_label_instruction()
        blk = self

        while result is None:
            if len(blk.goes_to) != 1:
                return None

            blk = blk.goes_to[0]
            result = blk.get_first_non_label_instruction()

        return result

    def guesses_initial_state_from_origin_blocks(self):
        """ Returns two dictionaries (regs, memory) that contains the common values
        of the cpustates of all comes_from blocks
        """
        if not self.comes_from:
            return {}, {}

        regs = self.comes_from[0].cpu.regs
        mems = self.comes_from[0].cpu.mem

        for blk in self.comes_from[1:]:
            regs = helpers.dict_intersection(regs, blk.cpu.regs)
            mems = helpers.dict_intersection(mems, blk.cpu.mem)

        return regs, mems

    def compute_cpu_state(self):
        """ Resets and updates internal cpu state of this block
        executing the instructions of the block. The block must be a basic block
        (i.e. already partitioned)
        """
        self.cpu.reset()

        for asm_line in self.code:
            self.cpu.execute(asm_line)

    def optimize(self, patterns_list):
        """ Tries to detect peep-hole patterns in this basic block
        and remove them.
        """
        if self.optimized:
            return

        changed = True
        code = self.code
        old_unary = dict(evaluator.Evaluator.UNARY)
        evaluator.Evaluator.UNARY['GVAL'] = lambda x: self.cpu.get(x)
        evaluator.Evaluator.UNARY['FLAGVAL'] = lambda x: {
            'c': str(self.cpu.C) if self.cpu.C is not None else helpers.new_tmp_val(),
            'z': str(self.cpu.Z) if self.cpu.Z is not None else helpers.new_tmp_val()
        }.get(x.lower(), helpers.new_tmp_val())

        if src.api.config.OPTIONS.optimization > 3:
            regs, mems = self.guesses_initial_state_from_origin_blocks()
        else:
            regs, mems = {}, {}

        while changed:
            changed = False
            self.cpu.reset(regs=regs, mems=mems)

            for i, asm_line in enumerate(code):
                for p in patterns_list:
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
                    matched = new_code[i: i + len(p.patt)]
                    new_code[i: i + len(p.patt)] = p.template.filter(match)
                    src.api.errmsg.info('pattern applied [{}:{}]'.format("%03i" % p.flag, p.fname))
                    src.api.debug.__DEBUG__('matched: \n    {}'.format('\n    '.join(matched)), level=1)
                    changed = new_code != code
                    if changed:
                        code = new_code
                        self.code = new_code
                        break

                if changed:
                    self.modified = True
                    break

                self.cpu.execute(asm_line)

        evaluator.Evaluator.UNARY.update(old_unary)  # restore old copy
        self.optimized = True


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

    for b_ in list(block.goes_to):
        block.delete_goes_to(b_)
        new_block.add_goes_to(b_)

    new_block.label_goes = block.label_goes
    block.label_goes = []

    new_block.next = block.next
    new_block.prev = block
    block.next = new_block
    new_block.add_comes_from(block)

    if new_block.next is not None:
        new_block.next.prev = new_block
        if block in new_block.next.comes_from:
            new_block.next.delete_comes_from(block)
            new_block.next.add_comes_from(new_block)

    block.update_next_block()

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

        for i, mem in enumerate(block):
            if i and mem.code == EDP:  # END_PROGRAM label always starts a basic block
                block, new_block = block_partition(block, i - 1)
                LABELS[END_PROGRAM_LABEL].basic_block = new_block
                break

            if mem.is_ender:
                block, new_block = block_partition(block, i)
                if not mem.condition_flag:
                    block.delete_goes_to(new_block)

                for l in mem.opers:
                    if l in LABELS:
                        JUMP_LABELS.add(l)
                        block.label_goes.append(l)
                break

            if mem.is_label and mem.code[:-1] not in LABELS:
                raise OptimizerError("Missing label '{}' in labels list".format(mem.code[:-1]))

            if mem.code in src.arch.zx48k.backend.ASMS:  # An inline ASM block
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
        for i, cell in enumerate(blk):
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

    for b in result:
        b.update_goes_and_comes()

    return result
