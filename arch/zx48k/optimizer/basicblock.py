# -*- coding: utf-8 -*-

from api.debug import __DEBUG__
from identityset import IdentitySet
from .memcell import MemCell
from .labelinfo import LabelInfo
from .helpers import ALL_REGS, LO16, HI16
from .common import LABELS, JUMP_LABELS

from . import helpers
from .. import backend


class BasicBlock(object):
    """ A Class describing a basic block
    """

    def __init__(self, memory):
        """ Initializes the internal array of instructions.
        """
        self.mem = [MemCell(asm, i) for i, asm in enumerate(memory)]
        self.asm = [x.asm for x in self.mem]
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

    def __len__(self):
        return len(self.mem)

    def __str__(self):
        return '\n'.join(str(x) for x in self.asm)

    def __getitem__(self, key):
        return self.mem[key]

    def __setitem__(self, key, value):
        self.mem[key].asm = value
        self.asm[key] = value

    def pop(self, i):
        self.mem.pop(i)
        return self.asm.pop(i)

    def insert(self, i, value):
        self.mem.insert(i, MemCell(value, i))
        self.asm.insert(i, value)

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

        if any(x.is_ender or x.asm in backend.ASMS for x in self.mem):
            return True

        for label in JUMP_LABELS:
            if LABELS[label].basic_block == self and (not self.mem[0].is_label or self.mem[0].inst != label):
                return True

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
            if oper[0] in LABELS.keys():
                self.add_goes_to(LABELS[oper[0]].basic_block)

        elif inst in ('jp', 'jr') and cond is None:
            if oper[0] in LABELS.keys():
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

        regs = list(regs)  # make a copy
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
        result = []

        for ii in range(i, end_):
            for r in self.mem[ii].requires:
                r = r.lower()
                if r in regs:
                    result.append(r)
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
        self.asm[a], self.asm[b] = self.asm[b], self.asm[a]

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
        changed = OPTIONS.optimization.value > 2  # only with -O3 will enter here

        while changed:
            changed = False
            regs = Registers()

            if len(self) and self[-1].inst in ('jp', 'jr') and \
                    self.original_next is LABELS[self[-1].opers[0]].basic_block:
                # { jp Label ; Label: ; ... } => { Label: ; ... }
                LABELS[self[-1].opers[0]].used_by.remove(self)
                self.pop(len(self) - 1)
                changed = True
                continue

            for i in range(len(self)):
                try:
                    if self.mem[i].is_label:
                        # ignore labels
                        continue
                except IndexError:
                    print(i)
                    print('\n'.join(str(x) for x in self.mem))
                    raise

                i1 = self.mem[i].inst
                o1 = self.mem[i].opers

                if i > 0:
                    i0 = self.mem[i - 1].inst
                    o0 = self.mem[i - 1].opers
                else:
                    i0 = o0 = None

                if i < len(self) - 1:
                    i2 = self.mem[i + 1].inst
                    o2 = self.mem[i + 1].opers
                else:
                    i2 = o2 = None

                if i < len(self) - 2:
                    i3 = self.mem[i + 2].inst
                    o3 = self.mem[i + 2].opers
                else:
                    i3 = o3 = None

                if i1 == 'ld':
                    if OPT00 and o1[0] == o1[1]:
                        # { LD X, X } => {}
                        self.pop(i)
                        changed = True
                        break

                    if OPT01 and o0 == 'ld' and o0[0] == o1[1] and o1[0] == o0[1]:
                        # { LD A, X; LD X, A} => {LD A, X}
                        self.pop(i)
                        changed = True
                        break

                    if OPT02 and i0 == i1 == 'ld' and o0[1] == o1[1] and \
                            is_register(o0[0]) and is_register(o1[0]) and not is_16bit_idx_register(o1[0]):
                        if is_8bit_register(o1[0]):
                            if not is_8bit_register(o1[1]):
                                # { LD r1, N; LD r2, N} => {LD r1, N; LD r2, r1}
                                changed = True
                                self[i] = 'ld %s, %s' % (o1[0], o0[0])
                                break
                        else:
                            changed = True
                            # {LD r1, NN; LD r2, NN} => { LD r1, NN; LD r2H, r1H; LD r2L, r1L}
                            self[i] = 'ld %s, %s' % (HI16(o1[0]), HI16(o0[0]))
                            self.insert(i + 1, 'ld %s, %s' % (LO16(o1[0]), LO16(o0[0])))
                            break

                    if OPT03 and is_register(o1[0]) and o1[0] != 'sp' and \
                            not self.is_used(single_registers(o1[0]), i + 1):
                        # LD X, nnn ; X not used later => Remove instruction
                        tmp = str(self.asm)
                        self.pop(i)
                        changed = True
                        __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                        break

                    if OPT04 and o1 == ['h', 'a'] and i2 == 'ld' and o2[0] == 'a' \
                            and i3 == 'sub' and o3[0] == 'h' and not self.is_used('h', i + 3):
                        if is_number(o2[1]):
                            self[i] = 'neg'
                            self[i + 1] = 'add a, %s' % o2[1]
                            self[i + 2] = 'ccf'
                            changed = True
                            break

                    if OPT05 and regs._is(o1[0], o1[1]):  # and regs.get(o1[0])[0:3] != '(ix':
                        tmp = str(self.asm)
                        self.pop(i)
                        changed = True
                        __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                        break

                    if OPT06 and o1[0] in ('hl', 'de') and \
                            i2 == 'ex' and o2[0] == 'de' and o2[1] == 'hl' and \
                            not self.is_used(single_registers(o1[0]), i + 2):
                        # { LD HL, XX ; EX DE, HL; POP HL } ::= { LD DE, XX ; POP HL }
                        reg = 'de' if o1[0] == 'hl' else 'hl'
                        self.pop(i + 1)
                        self[i] = 'ld %s, %s' % (reg, o1[1])
                        changed = True
                        break

                    if OPT07 and i0 == 'ld' and i2 == 'ld' and o2[1] == 'hl' and not self.is_used(['h', 'l'], i + 2) \
                            and (o0[0] == 'h' and o0[1] == 'b' and o1[0] == 'l' and o1[1] == 'c' or
                                 o0[0] == 'l' and o0[1] == 'c' and o1[0] == 'h' and o1[1] == 'b' or
                                 o0[0] == 'h' and o0[1] == 'd' and o1[0] == 'l' and o1[1] == 'e' or
                                 o0[0] == 'l' and o0[1] == 'e' and o1[0] == 'h' and o1[1] == 'd'):
                        # { LD h, rH ; LD l, rl ; LD (XX), HL } ::= { LD (XX), R }
                        tmp = str(self.asm)
                        r2 = 'de' if o0[1] in ('d', 'e') else 'bc'
                        self[i + 1] = 'ld %s, %s' % (o2[0], r2)
                        self.pop(i)
                        self.pop(i - 1)
                        changed = True
                        __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                        break

                    if OPT08 and i1 == i2 == 'ld' and i > 0 and \
                            (o1[1] == 'h' and o1[0] == 'b' and o2[1] == 'l' and o2[0] == 'c' or
                             o1[1] == 'l' and o1[0] == 'c' and o2[1] == 'h' and o2[0] == 'b' or
                             o1[1] == 'h' and o1[0] == 'd' and o2[1] == 'l' and o2[0] == 'e' or
                             o1[1] == 'l' and o1[0] == 'e' and o2[1] == 'h' and o2[
                             0] == 'd') and \
                            regs.get('hl') is not None and not self.is_used(['h', 'l'], i + 2) and \
                            not self[i - 1].needs(['h', 'l']) and not self[i - 1].affects(['h', 'l']):
                        # { LD HL, XXX ; <inst> ; LD rH, H; LD rL, L } ::= { LD HL, XXX ; LD rH, H; LD rL, L; <inst> }
                        changed = True
                        tmp = str(self.asm)
                        self.swap(i - 1, i + 1)
                        __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                        break

                    if OPT09 and i > 0 and i0 == i1 == i2 == 'ld' and \
                            o0[0] == 'hl' and \
                            (o1[1] == 'h' and o1[0] == 'b' and o2[1] == 'l' and o2[0] == 'c' or
                             o1[1] == 'l' and o1[0] == 'c' and o2[1] == 'h' and o2[0] == 'b' or
                             o1[1] == 'h' and o1[0] == 'd' and o2[1] == 'l' and o2[0] == 'e' or
                             o1[1] == 'l' and o1[0] == 'e' and o2[1] == 'h' and o2[0] == 'd') and \
                            not self.is_used(['h', 'l'], i + 2):
                        # { LD HL, XXX ;  LD rH, H; LD rL, L } ::= { LD rr, XXX }
                        changed = True
                        r1 = 'de' if o1[0] in ('d', 'e') else 'bc'
                        tmp = str(self.asm)
                        self[i - 1] = 'ld %s, %s' % (r1, o0[1])
                        self.pop(i + 1)
                        self.pop(i)
                        __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                        break

                if OPT10 and i1 in ('inc', 'dec') and o1[0] == 'a':
                    if i2 == i0 == 'ld' and o2[0] == o0[1] and 'a' == o0[0] == o2[1] and o0[1][0] == '(':
                        if not RE_INDIR.match(o2[0]):
                            if not self.is_used(['a', 'h', 'l'], i + 2):
                                # { LD A, (X); [ DEC A | INC A ]; LD (X), A} ::= {LD HL, X; [ DEC (HL) | INC (HL) ]}
                                tmp = str(self.asm)
                                self.pop(i + 1)
                                self[i - 1] = 'ld hl, %s' % (o0[1][1:-1])
                                self[i] = '%s (hl)' % i1
                                changed = True
                                __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                                break
                        else:
                            if not self.is_used(['a'], i + 2):
                                # { LD A, (IX + n); [ DEC A | INC A ]; LD (X), A} ::=
                                # { [ DEC (IX + n) | INC (IX + n) ] }
                                tmp = str(self.asm)
                                self.pop(i + 1)
                                self.pop(i)
                                self[i - 1] = '%s %s' % (i1, o0[1])
                                changed = True
                                __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                                break

                if OPT11 and i0 == 'push' and i3 == 'pop' and o0[0] != o3[0] \
                        and o0[0] in ('hl', 'de') and o3[0] in ('hl', 'de') \
                        and i1 == i2 == 'ld' and (
                        o1[0] == HI16(o0[0]) and o2[0] == LO16(o0[0]) and o1[1] == HI16(o3[0]) and
                        o2[1] == LO16(o3[0]) or
                        o2[0] == HI16(o0[0]) and o1[0] == LO16(o0[0]) and o2[1] == HI16(
                        o3[0]) and o1[1] == LO16(o3[0])):
                    # { PUSH HL; LD H, D; LD L, E; POP HL } ::= {EX DE, HL}
                    self.pop(i + 2)
                    self.pop(i + 1)
                    self.pop(i)
                    self[i - 1] = 'ex de, hl'
                    changed = True
                    break

                if i0 == 'push' and i1 == 'pop':
                    if OPT12 and o0[0] == o1[0]:
                        # { PUSH X ; POP X } ::= { }
                        self.pop(i)
                        self.pop(i - 1)
                        changed = True
                        break

                    if OPT13 and o0[0] in ('de', 'hl') and o1[0] in ('de', 'hl') and not self.is_used(
                            single_registers(o0[0]), i + 1):
                        # { PUSH DE ; POP HL } ::= { EX DE, HL }
                        self.pop(i)
                        self[i - 1] = 'ex de, hl'
                        changed = True
                        break

                    if OPT14 and 'af' in (o0[0], o1[0]):
                        # { push Xx ; pop af } => { ld a, X }
                        if not self.is_used(o1[0][1], i + 1):
                            self[i - 1] = 'ld %s, %s' % (HI16(o1[0]), HI16(o0[0]))
                            self.pop(i)
                            changed = True
                            break
                    elif OPT15 and not is_16bit_idx_register(o0[0]) and not is_16bit_idx_register(
                            o1[0]) and 'af' not in (o0[0], o1[0]):
                        # { push Xx ; pop Yy } => { ld Y, X ; ld y, x }
                        self[i - 1] = 'ld %s, %s' % (HI16(o1[0]), HI16(o0[0]))
                        self[i] = 'ld %s, %s' % (LO16(o1[0]), LO16(o0[0]))
                        changed = True
                        break

                if OPT16 and i > 0 and not self.mem[i - 1].is_label and i1 == 'pop' and \
                        (not self.mem[i - 1].affects([o1[0], 'sp']) or
                         self.safe_to_write(o1[0], i + 1)) and \
                        not self.mem[i - 1].needs([o1[0], 'sp']):
                    # { <inst>;  POP X } => { POP X; <inst> } ; if inst does not uses X
                    tmp = str(self.asm)
                    self.swap(i - 1, i)
                    changed = True
                    __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                    break

                if OPT17 and i1 == 'xor' and o1[0] == 'a' and regs._is('a', 0) and regs.Z and not regs.C:
                    tmp = str(self.asm)
                    self.pop(i)
                    __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                    changed = True
                    break

                if OPT18 and i3 is not None and \
                        (i0 == i1 == 'ld' and i2 == i3 == 'push') and \
                        (o0[0] == o3[0] == 'de' and o1[0] == o2[0] == 'bc'):  # and \
                    if not self.is_used(['h', 'l', 'd', 'e', 'b', 'c'], i + 3):
                        # { LD DE, (X2) ; LD BC, (X1); PUSH DE; PUSH BC } ::=
                        # { LD HL, (X2); PUSH HL; LD HL, (X1); PUSH HL }
                        self[i - 1] = 'ld hl, %s' % o1[1]
                        self[i] = 'push hl'
                        self[i + 1] = 'ld hl, %s' % o0[1]
                        self[i + 2] = 'push hl'
                        changed = True
                        break

                if i1 in ('jp', 'jr', 'call') and o1[0] in JUMP_LABELS:
                    c = self.mem[i].condition_flag
                    if OPT19 and c is not None:
                        if c == 'c' and regs.C == 1 or \
                                c == 'z' and regs.Z == 1 or \
                                c == 'nc' and regs.C == 0 or \
                                c == 'nz' and regs.Z == 0:
                            # If the condition is always satisfied, replace with a simple jump / call
                            changed = True
                            tmp = str(self.asm)
                            self[i] = '%s %s' % (i1, o1[0])
                            self.update_goes_and_comes()
                            __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                            break

                    ii = LABELS[o1[0]].basic_block.get_first_non_label_instruction()
                    ii1 = None if ii is None else ii.inst
                    cc = None if ii is None else ii.condition_flag
                    # Are we calling / jumping into another jump?
                    if OPT20 and ii1 in ('jp', 'jr') and (
                            cc is None or
                            cc == c or
                            cc == 'c' and regs.C == 1 or
                            cc == 'z' and regs.Z == 1 or
                            cc == 'nc' and regs.C == 0 or
                            cc == 'nz' and regs.Z == 0):
                        if c is None:
                            c = ''
                        else:
                            c = c + ', '

                        changed = True
                        tmp = str(self.asm)
                        LABELS[o1[0]].used_by.remove(self)  # This block no longer uses this label
                        self[i] = '%s %s%s' % (i1, c, ii.opers[0])
                        self.update_goes_and_comes()
                        __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                        break

                if OPT22 and i0 == 'sbc' and o0[0] == o0[1] == 'a' and \
                        i1 == 'or' and o1[0] == 'a' and \
                        i2 == 'jp' and \
                        self[i + 1].condition_flag is not None and \
                        not self.is_used(['a'], i + 2):
                    c = self.mem[i + 1].condition_flag
                    if c in ('z', 'nz'):
                        c = 'c' if c == 'nz' else 'nc'
                        changed = True
                        self[i + 1] = 'jp %s, %s' % (c, o2[0])
                        self.pop(i)
                        self.pop(i - 1)
                        break

                if OPT23 and i0 == 'ld' and is_16bit_register(o0[0]) and o0[1][0] == '(' and \
                        i1 == 'ld' and o1[0] == 'a' and o1[1] == LO16(o0[0]) and not self.is_used(
                        single_registers(o0[0]), i + 1):
                    # { LD HL, (X) ; LD A, L } ::=  { LD A, (X) }
                    self.pop(i)
                    self[i - 1] = 'ld a, %s' % o0[1]
                    changed = True
                    break

                if OPT24 and i1 == i2 == 'ccf':  # { ccf ; ccf } ::= { }
                    self.pop(i)
                    self.pop(i)
                    changed = True
                    break

                if OPT25 and i1 == 'ld' and is_register(o1[0]) and o1[0] != 'sp':
                    is8 = is_8bit_register(o1[0])
                    ss = [x for x, y in regs.regs.items() if x != o1[0] and y is not None and y == regs.get(o1[1]) and
                          not is_8bit_register(o1[1])]
                    for r_ in ss:
                        if is8 != is_8bit_register(r_):
                            continue
                        changed = True
                        if is8:   # ld A, n; ld B, n => ld A, n; ld B, A
                            self[i] = 'ld %s, %s' % (o1[0], r_)
                        else:    # ld HL, n; ld DE, n => ld HL, n; ld d, h; ld e, l
                            # 16 bit register
                            self[i] = 'ld %s, %s' % (HI16(o1[0]), HI16(r_))
                            self.insert(i + 1, 'ld %s, %s' % (LO16(o1[0]), LO16(r_)))
                        break

                    if changed:
                        break

                if OPT26 and i1 == i2 == 'ld' and (o1[0], o1[1], o2[0], o2[1]) == ('d', 'h', 'e', 'l') and \
                        not self.is_used(['h', 'l'], i + 2):
                    self[i] = 'ex de, hl'
                    self.pop(i + 1)
                    changed = True
                    break

                if OPT27 and i1 in ('cp', 'or', 'and', 'add', 'adc', 'sub', 'sbc') and o1[-1] != 'a' and \
                        not self.is_used(o1[-1], i + 1) and i0 == 'ld' and o0[0] == o1[-1] and \
                        (o0[1] == '(hl)' or RE_IXIND.match(o0[1])):
                    template = '{0} %s{1}' % ('a, ' if i1 in ('add', 'adc', 'sbc') else '')
                    self[i] = template.format(i1, o0[1])
                    self.pop(i - 1)
                    changed = True
                    break

                regs.op(i1, o1)


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
