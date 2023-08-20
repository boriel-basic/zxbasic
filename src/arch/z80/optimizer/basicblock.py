# -*- coding: utf-8 -*-
from __future__ import annotations

from typing import Final, Iterable, Iterator, List

import src.api.config
import src.arch.z80.backend.common
from src.api.debug import __DEBUG__
from src.api.utils import first
from src.arch.z80.optimizer import helpers
from src.arch.z80.optimizer.common import JUMP_LABELS, LABELS
from src.arch.z80.optimizer.cpustate import CPUState
from src.arch.z80.optimizer.helpers import ALL_REGS
from src.arch.z80.optimizer.labelinfo import LabelInfo
from src.arch.z80.optimizer.memcell import MemCell
from src.arch.z80.optimizer.patterns import RE_ID_OR_NUMBER
from src.arch.z80.peephole import evaluator

__all__ = "BasicBlock", "DummyBasicBlock"


class BasicBlock(Iterable[MemCell]):
    """A Class describing a basic block"""

    __UNIQUE_ID = 0
    clean_asm_args = False

    def __new__(cls, *args, **kwargs):
        cls.__UNIQUE_ID += 1
        return super().__new__(cls)

    def __init__(self, memory: Iterable[str]):
        """Initializes the internal array of instructions."""
        self.mem: List[MemCell] = []
        self.next: BasicBlock | None = None  # Which (if any) basic block follows this one in memory
        self.prev: BasicBlock | None = None  # Which (if any) basic block precedes to this one in the code
        self.lock = False  # True if this block is being accessed by other subroutine
        self.comes_from: set[BasicBlock] = set()  # A list/tuple containing possible jumps to this block
        self.goes_to: set[BasicBlock] = set()  # A list/tuple of possible block to jump from here
        self.modified = False  # True if something has been changed during optimization
        self.called_by: set[BasicBlock] = set()
        self.label_goes = []
        self.ignored = False  # True if this block can be ignored (it's useless)
        self.id: Final[int] = BasicBlock.__UNIQUE_ID
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None
        self.optimized = False  # True if this block was already optimized
        self.code = memory
        self.cpu = CPUState()

    def __hash__(self) -> int:
        return self.id

    def __len__(self) -> int:
        return len(self.mem)

    def __str__(self) -> str:
        return "\n".join(x for x in self.code)

    def __repr__(self) -> str:
        return "<{}: id: {}, len: {}>".format(self.__class__.__name__, self.id, len(self))

    def __getitem__(self, key) -> MemCell | list[MemCell]:
        return self.mem[key]

    def __setitem__(self, key, value: MemCell):
        self.mem[key].asm = value
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None

    def __iter__(self) -> Iterator[MemCell]:
        for mem in self.mem:
            yield mem

    def pop(self, i: int) -> MemCell:
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None
        return self.mem.pop(i)

    def insert(self, i: int, value: str):
        memcell = MemCell(value, i)
        self.mem.insert(i, memcell)
        self._bytes = None
        self._sizeof = None
        self._max_tstates = None

    @property
    def code(self) -> List[str]:
        return [x.code for x in self.mem]

    @code.setter
    def code(self, value: Iterable[str]):
        assert isinstance(value, Iterable)
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
        """Returns length in bytes (number of bytes this block takes)"""
        if self._bytes is not None:
            return self._bytes

        self._bytes = list(x.bytes for x in self.mem)
        return self._bytes

    @property
    def sizeof(self):
        """Returns the size of this block in bytes once assembled"""
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
    def labels(self) -> tuple[str, ...]:
        """Returns a t-uple containing labels within this block, sorted by position in
        memory"""
        return tuple(cell.inst for cell in self.mem if cell.is_label)

    def get_first_partition_idx(self) -> int | None:
        """Returns the first position where this block can be
        partitioned or None if there's no such point
        """
        for i, mem in enumerate(self):
            if i > 0 and mem.is_label and mem.inst in JUMP_LABELS:
                return i

            if (mem.is_ender or mem.code in src.arch.z80.backend.common.ASMS) and i < len(self) - 1:
                return i + 1

        return None

    @property
    def is_partitionable(self) -> bool:
        """Returns if this block can be partitions in 2 or more blocks,
        because if contains enders.
        """
        return self.get_first_partition_idx() is not None

    def delete_comes_from(self, basic_block: BasicBlock | None) -> None:
        """Removes the basic_block ptr from the list for "comes_from"
        if it exists. It also sets self.prev to None if it is basic_block.
        """
        if basic_block is None:
            return

        if basic_block not in self.comes_from:
            return

        self.comes_from.remove(basic_block)
        basic_block.goes_to.remove(self)

    def delete_goes_to(self, basic_block: BasicBlock | None) -> None:
        """Removes the basic_block ptr from the list for "goes_to"
        if it exists. It also sets self.next to None if it is basic_block.
        """
        if basic_block is None:
            return

        if basic_block not in self.goes_to:
            return

        self.goes_to.remove(basic_block)
        basic_block.comes_from.remove(self)

    def add_comes_from(self, basic_block: BasicBlock | None) -> None:
        """This simulates a set. Adds the basic_block to the comes_from
        list if not done already.
        """
        if basic_block is None:
            return

        # Return if already added
        if basic_block in self.comes_from:
            return

        self.comes_from.add(basic_block)
        basic_block.goes_to.add(self)

    def add_goes_to(self, basic_block: BasicBlock | None) -> None:
        """This simulates a set. Adds the basic_block to the goes_to
        list if not done already.
        """
        if basic_block is None:
            return

        if basic_block in self.goes_to:
            return

        self.goes_to.add(basic_block)
        basic_block.comes_from.add(self)

    def update_next_block(self):
        """If the last instruction of this block is a JP, JR or RET (with no
        conditions) then goes_to set contains just a
        single block
        """
        last = self.mem[-1]
        if last.inst not in {"djnz", "jp", "jr", "call", "ret", "reti", "retn", "rst"}:
            return

        if last.inst in {"reti", "retn"}:
            if self.next is not None:
                self.next.delete_comes_from(self)
            return

        if self.next is not None and last.condition_flag is None:  # jp NNN, call NNN, rst, jr NNNN, ret
            self.next.delete_comes_from(self)
            for blk in self.goes_to:
                self.delete_goes_to(blk)

        if last.inst == "ret":
            return

        if last.opers[0] not in LABELS.keys():
            __DEBUG__("INFO: %s is not defined. No optimization is done." % last.opers[0], 2)
            LABELS[last.opers[0]] = LabelInfo(last.opers[0], 0, DummyBasicBlock(ALL_REGS, ALL_REGS))

        n_block = LABELS[last.opers[0]].basic_block
        self.add_goes_to(n_block)

    def is_used(self, regs: list[str], i: int, top: int | None = None) -> bool:
        """Checks whether any of the given regs are required from the given point
        to the end or not.
        """
        if self.lock:
            return True

        i = max(i, 0)
        top = len(self) if top is None else top + 1

        if regs and regs[0][0] == "(" and regs[0][-1] == ")":  # A memory address
            r16 = helpers.single_registers(regs[0][1:-1]) if helpers.is_16bit_oper_register(regs[0][1:-1]) else []
            ix = helpers.single_registers(helpers.idx_args(regs[0][1:-1])[0]) if helpers.idx_args(regs[0][1:-1]) else []

            rr = set(r16 + ix)
            mem_vars = set([] if rr else RE_ID_OR_NUMBER.findall(regs[0]))

            for mem in self[i:top]:  # For memory accesses only mark as NOT used if it's overwritten
                if mem.inst == "ld" and mem.opers[0] == regs[0]:
                    return False

                # And, Or, Xor uses both operands
                if mem.inst in {"and", "or", "xor"} and mem.opers[0] == regs[0]:
                    return True

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

    def requires(self, i: int = 0, end_: int | None = None) -> set[str]:
        """Returns a list of registers and variables this block requires.
        By default checks from the beginning (i = 0).
        :param i: initial position of the block to examine
        :param end_: final position to examine
        :returns: registers safe to write
        """
        i = max(i, 0)
        end_ = len(self) if end_ is None or end_ > len(self) else end_
        regs = {"a", "b", "c", "d", "e", "f", "h", "l", "i", "ixh", "ixl", "iyh", "iyl", "sp"}
        result: set[str] = set()

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

    def destroys(self, i: int = 0) -> list[str]:
        """Returns a list of registers this block destroys
        By default checks from the beginning (i = 0).
        """
        regs = {"a", "b", "c", "d", "e", "f", "h", "l", "i", "ixh", "ixl", "iyh", "iyl", "sp"}
        top = len(self)
        result: list[str] = []

        for ii in range(i, top):
            for r in self.mem[ii].destroys:
                if r in regs:
                    result.append(r)
                    regs.remove(r)

            if not regs:
                break

        return result

    def goes_requires(self, regs):
        """Returns whether any of the goes_to block requires any of
        the given registers.
        """
        for block in self.goes_to:
            if block.is_used(regs, 0):
                return True

        return False

    def get_first_non_label_instruction(self):
        """Returns the memcell of the given block, which is
        not a LABEL.
        """
        for mem in self:
            if not mem.is_label:
                return mem

        return None

    def get_next_exec_instruction(self) -> MemCell | None:
        """Return the first non label instruction to be executed, either
        in this block or in the following one. If there are more than one, return None.
        Also returns None if there is no instruction to be executed.
        """
        result = self.get_first_non_label_instruction()
        blk = self

        while result is None:
            if len(blk.goes_to) != 1:
                return None

            blk = next(iter(blk.goes_to))
            result = blk.get_first_non_label_instruction()

        return result

    def guesses_initial_state_from_origin_blocks(self) -> tuple[dict[str, str], dict[str, str]]:
        """Returns two dictionaries (regs, memory) that contains the common values
        of the cpustates of all comes_from blocks
        """
        if not self.comes_from:
            return {}, {}

        regs = first(self.comes_from).cpu.regs
        mems = first(self.comes_from).cpu.mem

        for blk in list(self.comes_from)[1:]:
            regs = helpers.dict_intersection(regs, blk.cpu.regs)
            mems = helpers.dict_intersection(mems, blk.cpu.mem)

        return regs, mems

    def compute_cpu_state(self):
        """Resets and updates internal cpu state of this block
        executing the instructions of the block. The block must be a basic block
        (i.e. already partitioned)
        """
        self.cpu.reset()

        for asm_line in self.code:
            self.cpu.execute(asm_line)

    def optimize(self, patterns_list):
        """Tries to detect peep-hole patterns in this basic block
        and remove them.
        """
        if self.optimized:
            return

        changed = True
        code = self.code
        old_unary = dict(evaluator.Evaluator.UNARY)
        evaluator.Evaluator.UNARY["GVAL"] = lambda x: self.cpu.get(x)
        evaluator.Evaluator.UNARY["FLAGVAL"] = lambda x: {
            "c": str(self.cpu.C) if self.cpu.C is not None else helpers.new_tmp_val(),
            "z": str(self.cpu.Z) if self.cpu.Z is not None else helpers.new_tmp_val(),
        }.get(x.lower(), helpers.new_tmp_val())

        if src.api.config.OPTIONS.optimization_level > 3:
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

                    evaluator.Evaluator.UNARY["IS_REQUIRED"] = lambda x: self.is_used([x], i + len(p.patt))
                    if not p.cond.eval(match):
                        continue

                    # all patterns matched successfully. Apply this rule
                    new_code = list(code)
                    matched = new_code[i : i + len(p.patt)]
                    new_code[i : i + len(p.patt)] = p.template.filter(match)
                    src.api.errmsg.info("pattern applied [{}:{}]".format("%03i" % p.flag, p.fname))
                    src.api.debug.__DEBUG__("matched: \n    {}".format("\n    ".join(matched)), level=1)
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
    """A dummy basic block with some basic information
    about what registers uses an destroys
    """

    def __init__(self, destroys: Iterable[str], requires: Iterable[str]):
        BasicBlock.__init__(self, [])
        self.__destroys = tuple(destroys)
        self.__requires = set(requires)
        self.code = ["ret"]

    def destroys(self, i: int = 0) -> list[str]:
        return list(self.__destroys)

    def requires(self, i: int = 0, end_=None) -> set[str]:
        return set(self.__requires)

    def is_used(self, regs: Iterable[str], i: int, top: int | None = None) -> bool:
        return len([x for x in regs if x in self.__requires]) > 0
