import re

from typing import Dict
from typing import Tuple
from typing import Optional
from typing import List

from .patterns import RE_OUTC, RE_INDIR16
from .helpers import single_registers
from src.libzxbasm import z80

# Dict of patterns to normalized instructions. I.e. 'ld a, 5' -> 'LD A,N'
Z80_PATTERN: Dict[re.Pattern, z80.Opcode] = {}


class Asm:
    """ Defines an asm instruction
    """
    def __init__(self, asm: str):
        asm = asm.strip()
        assert asm, "Empty instruction '{}'".format(asm)
        self.inst = Asm.instruction(asm)
        self.oper = Asm.opers(asm)
        self.asm = '{} {}'.format(self.inst, ' '.join(asm.split(' ', 1)[1:])).strip()
        self.cond = Asm.condition(asm)
        self.output = Asm.result(asm)
        self._bytes: Optional[Tuple[str]] = None
        self._max_tstates = None
        self.is_label = self.inst[-1] == ':'

    def _compute_bytes(self):
        for patt, opcode_data in Z80_PATTERN.items():
            if patt.match(self.asm):
                self._bytes = tuple(opcode_data.opcode.split())
                self._max_tstates = opcode_data.T
                return

        self._bytes = bytearray()
        self._max_tstates = 0

    @property
    def bytes(self):
        """ Returns the assembled bytes as a list of hexadecimal ones.
        Unknown bytes will be returned as 'XX'. e.g.:
        'ld a, 5' => ['3D', 'XX']
        Labels will return [] as they have no bytes
        """
        if self._bytes is None:
            self._compute_bytes()

        return self._bytes

    @property
    def max_tstates(self):
        """ Returns the max number of t-states this instruction takes to
        execute (conditional jumps have two possible values, returns the
        maximum)
        """
        if self._max_tstates is None:
            self._compute_bytes()

        return self._max_tstates

    @staticmethod
    def instruction(asm: str) -> str:
        tmp = asm.strip(' \t\n').split(' ', 1)[0]
        return tmp.lower() if tmp.upper() in z80.Z80INSTR else tmp

    @staticmethod
    def opers(inst: str) -> List[str]:
        """ Returns operands of an ASM instruction.
        Even "indirect" operands, like SP if RET or CALL is used.
        """
        car, cdr = (inst.strip(' \t\n') + ' ').split(' ', 1)
        I = car.lower()  # Instruction
        op = [x.strip() for x in cdr.split(',')]

        if I in {'call', 'jp', 'jr'} and len(op) > 1:
            op = op[1:] + ['f']

        elif I == 'djnz':
            op.append('b')

        elif I in {'push', 'pop', 'call'}:
            op.append('sp')  # Sp is also affected by push, pop and call

        elif I in {'or', 'and', 'xor', 'neg', 'cpl', 'rrca', 'rlca'}:
            op.append('a')

        elif I in {'rra', 'rla'}:
            op.extend(['a', 'f'])

        elif I in ('rr', 'rl'):
            op.append('f')

        elif I in {'adc', 'sbc'}:
            if len(op) == 1:
                op = ['a', 'f'] + op

        elif I in {'add', 'sub'}:
            if len(op) == 1:
                op = ['a'] + op

        elif I in {'ldd', 'ldi', 'lddr', 'ldir'}:
            op = ['hl', 'de', 'bc']

        elif I in {'cpd', 'cpi', 'cpdr', 'cpir'}:
            op = ['a', 'hl', 'bc']

        elif I == 'exx':
            op = ['*', 'bc', 'de', 'hl', 'b', 'c', 'd', 'e', 'h', 'l']

        elif I in {'ret', 'reti', 'retn'}:
            op += ['sp']

        elif I == 'out':
            if op and RE_OUTC.match(op[0]):
                op[0] = 'c'
            else:
                op.pop(0)

        elif I == 'in':
            if len(op) > 1 and RE_OUTC.match(op[1]):
                op[1] = 'c'
            else:
                op.pop(1)

        for i, o in enumerate(op):
            tmp = RE_INDIR16.match(o)
            if tmp is not None:
                op[i] = '(' + op[i].strip()[1:-1].strip().lower() + ')'  # '  (  dE )  ' => '(de)'

        return op

    @staticmethod
    def condition(asm):
        """ Returns the flag this instruction uses
        or None. E.g. 'c' for Carry, 'nz' for not-zero, etc.
        That is the condition required for this instruction
        to execute. For example: ADC A, 0 does NOT have a
        condition flag (it always execute) whilst RET C does.
        DJNZ has condition flag NZ
        """
        i = Asm.instruction(asm)

        if i not in {'call', 'jp', 'jr', 'ret', 'djnz'}:
            return None  # This instruction always execute

        if i == 'ret':
            asm = [x.lower() for x in asm.split(' ') if x != '']
            return asm[1] if len(asm) > 1 else None

        if i == 'djnz':
            return 'nz'

        asm = [x.strip() for x in asm.split(',')]
        asm = [x.lower() for x in asm[0].split(' ') if x != '']
        if len(asm) > 1 and asm[1] in {'c', 'nc', 'z', 'nz', 'po', 'pe', 'p', 'm'}:
            return asm[1]

        return None

    @staticmethod
    def result(asm):
        """ Returns which 8-bit registers (and SP for INC SP, DEC SP, etc.) are used by an asm
        instruction to return a result.
        """
        ins = Asm.instruction(asm)
        op = Asm.opers(asm)

        if ins in ('or', 'and') and op == ['a']:
            return ['f']

        if ins in {'xor', 'or', 'and', 'neg', 'cpl', 'daa', 'rld', 'rrd', 'rra', 'rla', 'rrca', 'rlca'}:
            return ['a', 'f']

        if ins in {'bit', 'cp', 'scf', 'ccf'}:
            return ['f']

        if ins in {'sub', 'add', 'sbc', 'adc'}:
            if len(op) == 1:
                return ['a', 'f']
            else:
                return single_registers(op[0]) + ['f']

        if ins == 'djnz':
            return ['b', 'f']

        if ins in {'ldir', 'ldi', 'lddr', 'ldd'}:
            return ['f', 'b', 'c', 'd', 'e', 'h', 'l']

        if ins in {'cpi', 'cpir', 'cpd', 'cpdr'}:
            return ['f', 'b', 'c', 'h', 'l']

        if ins in ('pop', 'ld'):
            return single_registers(op[0])

        if ins in {'inc', 'dec', 'sbc', 'rr', 'rl', 'rrc', 'rlc'}:
            return ['f'] + single_registers(op[0])

        if ins in ('set', 'res'):
            return single_registers(op[1])

        return []

    def __len__(self):
        return len(self.asm) > 0


def init():
    """ Initializes table of regexp -> dict entry
    """
    def make_patt(mnemo):
        """ Given a mnemonic returns it's pattern tu match it
        """
        return r'^[ \t]*{}[ \t]*$'.format(RE_.sub('.+', re.escape(mnemo).replace(',', r',[ \t]*')))

    RE_ = re.compile(r'\bN+\b')
    for mnemo, opcode_data in z80.Z80SET.items():
        pattern = make_patt(mnemo)
        Z80_PATTERN[re.compile(pattern, flags=re.IGNORECASE)] = opcode_data

    Z80_PATTERN[re.compile(make_patt('DEFB NN'), flags=re.IGNORECASE)] = z80.Opcode('DEFB NN', 0, 1, 'XX')
    Z80_PATTERN[re.compile(make_patt('DEFW NNNN'), flags=re.IGNORECASE)] = z80.Opcode('DEFW NNNN', 0, 2, 'XX XX')


init()
