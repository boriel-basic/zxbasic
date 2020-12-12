# -*- coding: utf-8 -*-

import re

from typing import Optional
from typing import List
from typing import Union
from typing import Set

from . import helpers
from .. import backend
from .asm import Asm
from src.api.utils import flatten_list
from src.libzxbasm import asmlex


class MemCell:
    """ Class describing a memory address.
    It just contains the addr (memory array index), and
    the instruction.
    """
    __instr: Asm

    def __init__(self, instr: str, addr: int):
        self.addr = addr
        self.asm = instr  # type: ignore

    @property
    def asm(self) -> Asm:
        return self.__instr

    @asm.setter
    def asm(self, value: str):
        self.__instr = Asm(value)

    @property
    def code(self) -> str:
        return self.asm.asm

    def __str__(self) -> str:
        return self.asm.asm

    def __repr__(self) -> str:
        return '{0}:{1}'.format(self.addr, str(self))

    def __len__(self) -> int:
        return len(self.asm)

    @property
    def bytes(self):
        """ Bytes (unresolved) to compose this instruction
        """
        return self.asm.bytes

    @property
    def sizeof(self) -> int:
        """ Size in bytes of this cell
        """
        return len(self.bytes)

    @property
    def max_tstates(self) -> int:
        """ Max number of t-states (time) this cell takes
        """
        return self.asm.max_tstates

    @property
    def is_label(self) -> bool:
        """ Returns whether the current addr
        contains a label.
        """
        return self.asm.is_label

    @property
    def is_ender(self) -> bool:
        """ Returns if this instruction is a BLOCK ender
        """
        return self.inst in helpers.BLOCK_ENDERS

    @property
    def inst(self) -> str:
        """ Returns just the asm instruction in lower
        case. E.g. 'ld', 'jp', 'pop'
        """
        if self.is_label:
            return self.asm.asm[:-1]

        return self.asm.inst

    @property
    def condition_flag(self) -> Optional[str]:
        """ Returns the flag this instruction uses
        or None. E.g. 'c' for Carry, 'nz' for not-zero, etc.
        That is the condition required for this instruction
        to execute. For example: ADC A, 0 does NOT have a
        condition flag (it always execute) whilst RETC does.
        """
        return self.asm.cond

    @property
    def opers(self) -> List[str]:
        """ Returns a list of operands (i.e. register) this mnemonic uses
        """
        return self.asm.oper

    @property
    def destroys(self) -> Set[str]:
        """ Returns which single registers (including f, flag)
        this instruction changes.

        Registers are: a, b, c, d, e, i, h, l, ixh, ixl, iyh, iyl, r

        LD a, X => Destroys a
        LD a, a => Destroys nothing

        INC a => Destroys a, f
        POP af => Destroys a, f, sp
        PUSH af => Destroys sp

        ret => Destroys SP
        """
        if self.code in backend.ASMS:
            return helpers.ALL_REGS

        res: Set[str] = set()
        i = self.inst
        o = self.opers

        if i in {'push', 'ret', 'call', 'rst', 'reti', 'retn'}:
            return {'sp'}

        if i == 'pop':
            res.update('sp', helpers.single_registers(o[:1]))
        elif i in {'ldir', 'lddr'}:
            res.update('b', 'c', 'd', 'e', 'h', 'l', 'f')
        elif i in {'ldd', 'ldi'}:
            res.update('b', 'c', 'd', 'e', 'h', 'l', 'f')
        elif i in {'otir', 'otdr', 'oti', 'otd', 'inir', 'indr', 'ini', 'ind'}:
            res.update('h', 'l', 'b')
        elif i in {'cpir', 'cpi', 'cpdr', 'cpd'}:
            res.update('h', 'l', 'b', 'c', 'f')
        elif i in ('ld', 'in'):
            res.update(helpers.single_registers(o[:1]))
        elif i in ('inc', 'dec'):
            res.update('f', helpers.single_registers(o[:1]))
        elif i == 'exx':
            res.update('b', 'c', 'd', 'e', 'h', 'l')
        elif i == 'ex':
            res.update(helpers.single_registers(o[0]))
            res.update(helpers.single_registers(o[1]))
        elif i in {'ccf', 'scf', 'bit', 'cp'}:
            res.add('f')
        elif i in {'or', 'and'}:
            res.add('f')
            if o[0] != 'a':
                res.add('a')
        elif i in {'xor', 'add', 'adc', 'sub', 'sbc'}:
            if len(o) > 1:
                res.update(helpers.single_registers(o[0]))
            else:
                res.add('a')
            res.add('f')
        elif i in {'neg', 'cpl', 'daa', 'rra', 'rla', 'rrca', 'rlca', 'rrd', 'rld'}:
            res.update('a', 'f')
        elif i == 'djnz':
            res.update('b', 'f')
        elif i in {'rr', 'rl', 'rrc', 'rlc', 'srl', 'sra', 'sll', 'sla'}:
            res.update(helpers.single_registers(o[0]))
            res.add('f')
        elif i in ('set', 'res'):
            res.update(helpers.single_registers(o[1]))

        return res

    @property
    def requires(self) -> Set[str]:
        """ Returns the registers, operands, etc. required by an instruction.
        """
        if self.code in backend.ASMS:
            return helpers.ALL_REGS

        if self.inst == '#pragma':
            tmp = self.code.split(' ')[1:]
            if tmp[0] != 'opt':
                return set()
            if tmp[1] == 'require':
                return set(flatten_list([helpers.single_registers(x.strip(', \t\r')) for x in tmp[2:]]))

            return set()

        result = set()
        i = self.inst
        o = [x.lower() for x in self.opers]

        if i in ['ret', 'pop', 'push']:
            result.add('sp')

        if self.condition_flag is not None or i in ['sbc', 'adc']:
            result.add('f')

        for O in o:
            if '(hl)' in O:
                result.add('h')
                result.add('l')

            if '(de)' in O:
                result.add('d')
                result.add('e')

            if '(bc)' in O:
                result.add('b')
                result.add('c')

            if '(sp)' in O:
                result.add('sp')

            if '(ix' in O:
                result.add('ixh')
                result.add('ixl')

            if '(iy' in O:
                result.add('iyh')
                result.add('iyl')

        if i in ['ccf']:
            result.add('f')

        elif i in {'rra', 'rla', 'rrca', 'rlca'}:
            result.add('a')
            result.add('f')

        elif i in ['xor', 'cp']:
            # XOR A, and CP A don't need the a register
            if o[0] != 'a':
                result.add('a')

                if o[0][0] != '(' and not helpers.is_number(o[0]):
                    result = result.union(helpers.single_registers(o))

        elif i in ['or', 'and']:
            # AND A, and OR A do need the a register to compute Z flag
            result.add('a')

            if o[0][0] != '(' and not helpers.is_number(o[0]):
                result = result.union(helpers.single_registers(o))

        elif i in {'adc', 'sbc', 'add', 'sub'}:
            if len(o) == 1:
                if i not in ('sub', 'sbc') or o[0] != 'a':
                    # sbc a and sub a dont' need the a register
                    result.add('a')

                if o[0][0] != '(' and not helpers.is_number(o[0]):
                    result = result.union(helpers.single_registers(o))
            else:
                if o[0] != o[1] or i in ('add', 'adc'):
                    # sub HL, HL or sub X, X don't need the X register(s)
                    result = result.union(helpers.single_registers(o))

            if i in ['adc', 'sbc']:
                result.add('f')

        elif i in {'daa', 'rld', 'rrd', 'neg', 'cpl'}:
            result.add('a')

        elif i in {'rl', 'rr', 'rlc', 'rrc'}:
            result = result.union(helpers.single_registers(o) + ['f'])

        elif i in {'sla', 'sll', 'sra', 'srl', 'inc', 'dec'}:
            result = result.union(helpers.single_registers(o))

        elif i == 'djnz':
            result.add('b')

        elif i in {'ldir', 'lddr', 'ldi', 'ldd'}:
            result = result.union(['b', 'c', 'd', 'e', 'h', 'l'])

        elif i in {'cpi', 'cpd', 'cpir', 'cpdr'}:
            result = result.union(['a', 'b', 'c', 'h', 'l'])

        elif i == 'ld' and not helpers.is_number(o[1]):
            result = result.union(helpers.single_registers(o[1]))

        elif i == 'ex':
            if o[0] == 'de':
                result = result.union(['d', 'e', 'h', 'l'])
            elif o[1] == '(sp)':
                result = result.union(['h', 'l'])  # sp already included
            else:
                result = result.union(['a', 'f', "a'", "f'"])

        elif i == 'exx':
            result = result.union(['b', 'c', 'd', 'e', 'h', 'l'])

        elif i == 'push':
            result = result.union(helpers.single_registers(o))

        elif i in {'bit', 'set', 'res'}:
            result = result.union(helpers.single_registers(o[1]))

        elif i == 'out':
            result.add(o[1])
            if o[0] == 'c':
                result.update('b', 'c')

        elif i == 'in':
            if o[1] == 'c':
                result.update('b', 'c')

        elif i == 'im':
            result.add('i')

        return result

    def affects(self, reglist: Union[List[str], str]) -> bool:
        """ Returns if this instruction affects any of the registers
        in reglist.
        """
        if isinstance(reglist, str):
            reglist = [reglist]

        reglist = helpers.single_registers(reglist)
        return bool([x for x in self.destroys if x in reglist])

    def needs(self, reglist: Union[List[str], str]) -> bool:
        """ Returns if this instruction need any of the registers
        in reglist.
        """
        if isinstance(reglist, str):
            reglist = [reglist]

        reglist = helpers.single_registers(reglist)
        return bool([x for x in self.requires if x in reglist])

    @property
    def used_labels(self) -> List[str]:
        """ Returns a list of required labels for this instruction
        """
        result: List[str] = []
        tmp = self.asm.asm

        if not len(tmp) or tmp[0] in ('#', ';'):
            return result

        try:
            tmpLexer = asmlex.lex.lex(object=asmlex.Lexer())
            tmpLexer.input(tmp)

            while True:
                token = tmpLexer.token()
                if not token:
                    break

                if token.type == 'ID':
                    result += [token.value]
        except Exception:
            pass

        return result

    def replace_label(self, old_label: str, new_label: str):
        """ Replaces old label with a new one
        """
        if old_label == new_label:
            return

        tmp = re.compile(r'\b' + old_label + r'\b')
        last = 0
        l = len(new_label)

        while True:
            match = tmp.search(self.inst)
            if not match:
                break

            txt = self.inst
            self.asm = txt[:last + match.start()] + new_label + txt[last + match.end():]
            last += match.start() + l
