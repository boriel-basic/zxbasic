from .patterns import RE_OUTC, RE_INDIR16
from .helpers import single_registers


class Asm(object):
    """ Defines an asm instruction
    """
    def __init__(self, asm):
        assert isinstance(asm, str)
        self.inst = Asm.inst(asm)
        self.oper = Asm.opers(asm)
        self.asm = '{} {}'.format(self.inst, ' '.join(asm.split(' ', 1)[1:])).strip()
        self.cond = Asm.condition(asm)
        self.output = Asm.result(asm)

    @staticmethod
    def inst(asm):
        tmp = asm.strip(' \t\n').split(' ', 1)[0]
        return tmp if tmp[-1] == ':' else tmp.lower()

    @staticmethod
    def opers(inst):
        """ Returns operands of an ASM instruction.
        Even "indirect" operands, like SP if RET or CALL is used.
        """
        i = inst.strip(' \t\n').split(' ')
        I = i[0].lower()  # Instruction
        i = ''.join(i[1:])

        op = i.split(',')
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
            if len(op) and RE_OUTC.match(op[0]):
                op[0] = 'c'
            else:
                op.pop(0)

        elif I == 'in':
            if len(op) > 1 and RE_OUTC.match(op[1]):
                op[1] = 'c'
            else:
                op.pop(1)

        for i in range(len(op)):
            tmp = RE_INDIR16.match(op[i])
            if tmp is not None:
                op[i] = '(' + op[i].strip()[1:-1].strip().lower() + ')'  # '  (  dE )  ' => '(de)'

        return op

    @staticmethod
    def condition(asm):
        """ Returns the flag this instruction uses
        or None. E.g. 'c' for Carry, 'nz' for not-zero, etc.
        That is the condition required for this instruction
        to execute. For example: ADC A, 0 does NOT have a
        condition flag (it always execute) whilst RETC does.
        """
        i = Asm.inst(asm)

        if i not in {'call', 'jp', 'jr', 'ret'}:
            return None  # This instruction always execute

        if i == 'ret':
            asm = [x.lower() for x in asm.split(' ') if x != '']
            return asm[1] if len(asm) > 1 else None

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
        ins = Asm.inst(asm)
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