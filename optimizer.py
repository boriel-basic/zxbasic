#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:et:ai:sw=4:

# -----------------------------------------------------------------------------
# An peephole optimizer using some simple rules
# -----------------------------------------------------------------------------

import re
from api.errors import Error
from api.config import OPTIONS
from api.debug import __DEBUG__
from identityset import IdentitySet
import sys
import asmlex

END_PROGRAM_LABEL = '__END_PROGRAM'  # Label for end program

sys.setrecursionlimit(10000)
# Labels which must start a basic block, because they're used in a JP/CALL
LABELS = {}  # Label -> LabelInfo object

JUMP_LABELS = set([])
MEMORY = []  # Instructions emmited by backend

# Instructions that ends a BLOCK
BLOCK_ENDERS = ('jr', 'jp', 'call', 'ret', 'reti', 'retn', 'djnz', 'rst')

# PROC labels name space counter
PROC_COUNTER = 0

BLOCKS = []  # Memory blocks

# Al registers (even f FLAG registers)
ALL_REGS = ['a', 'b', 'c', 'd', 'e', 'f', 'h', 'l',
            'ixh', 'ixl', 'iyh', 'iyl', 'r', 'i']

RE_NUMBER = re.compile('^([-+]?[0-9]+|$[A-Fa-f0-9]+|[0-9][A-Fa-f0-9]*[Hh]|%[01]+|[01]+[bB])$')
RE_INDIR = re.compile(r'\([ \t]*[Ii][XxYy][ \t]*[-+][ \t]*[0-9]+[ \t]*\)')
RE_IXIND = re.compile(r'[iI][xXyY]([-+][0-9]+)?')
RE_LABEL = re.compile(r'^[ \t]*[_a-zA-Z][a-zA-Z\d]*:')
RE_INDIR16 = re.compile('r[ \t]*\([ \t]*([dD][eE])|([hH][lL])[ \t]*\)[ \t]*')
RE_OUTC = re.compile('[ \t]*\([ \t]*[cC]\)')

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


def is_8bit_normal_register(x):
    return x.lower() in ('a', 'b', 'c', 'd', 'e', 'i', 'h', 'l')


def is_8bit_idx_register(x):
    return x.lower() in ('ixh', 'ixl', 'iyh', 'iyl')


def is_8bit_register(x):
    return x.lower() in ('a', 'b', 'c', 'd', 'e', 'i', 'h', 'l', 'ixh', 'ixl', 'iyh', 'iyl')


def is_16bit_normal_register(x):
    return x.lower() in ('bc', 'de', 'hl')


def is_16bit_idx_register(x):
    return x.lower() in ('ix', 'iy')


def is_16bit_register(x):
    return x.lower() in ('bc', 'de', 'hl', 'ix', 'iy')


def LO16(x):
    if is_16bit_idx_register(x):
        return x.lower() + 'l'

    return x.lower()[1] + ("'" if "'" in x else '')


def HI16(x):
    if is_16bit_idx_register(x):
        return x.lower() + 'h'

    return x.lower()[0] + ("'" if "'" in x else '')


def is_register(x):
    ''' True if x is a register.
    '''
    if not isinstance(x, str):
        return False

    return x.lower() in ('a', 'b', 'c', 'd', 'e', 'h', 'l', \
                         'bc', 'de', 'hl', 'sp', 'ix', 'iy', 'ixh', 'ixl', 'iyh', 'iyl', \
                         'af', "af'", 'i', 'r')


def is_number(x):
    if x is None:
        return False

    if isinstance(x, int) or isinstance(x, float):
        return True

    try:
        tmp = eval(x, {}, {})
        if isinstance(tmp, int) or isinstance(tmp, float):
            return True
    except:
        pass

    return RE_NUMBER.match(str(x)) is not None


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


def oper(inst):
    """ Returns operands of an ASM instruction.
    Even "indirect" operands, like SP if RET or CALL is used.
    """
    i = inst.strip(' \t\n').split(' ')
    I = i[0].lower()  # Instruction
    i = ''.join(i[1:])

    op = i.split(',')
    if I in ('call', 'jp', 'jr') and len(op) > 1:
        op = op[1:] + ['f']

    elif I == 'djnz':
        op.append('b')

    elif I in ('push', 'pop', 'call'):
        op.append('sp')  # Sp is also affected by push, pop and call

    elif I in ('or', 'and', 'xor', 'neg', 'cpl', 'rrca', 'rlca', 'rra', 'rla'):
        op.extend(['a', 'f', 'af'])

    elif I in ('rr', 'rl'):
        op.append('f')

    elif I in ('add', 'adc', 'sub', 'sbc'):
        if len(op) == 1:
            op = ['a', 'f'] + op + ['af']

    elif I in ('ldd', 'ldi', 'lddr', 'ldir'):
        op = ['hl', 'de', 'bc']

    elif I in ('cpd', 'cpi', 'cpdr', 'cpir'):
        op = ['a', 'hl', 'bc']

    elif I == 'exx':
        op = ['*', 'bc', 'de', 'hl', 'b', 'c', 'd', 'e', 'h', 'l']

    elif I in ('ret', 'reti', 'retn'):
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


def inst(i):
    i = i.strip(' \t\n').split(' ')
    return i[0].lower()


def condition(i):
    ''' Returns the flag this instrunction uses
    or None. E.g. 'c' for Carry, 'nz' for not-zero, etc.
    That is the condition required for this instruction
    to execute. For example: ADC A, 0 does NOT have a
    condition flag (it always execute) whilst RETC does.
    '''
    I = inst(i)

    if I not in ('call', 'jp', 'jr', 'ret'):
        return None  # This instruction always execute

    if I == 'ret':
        i = [x.lower() for x in i.split(' ') if x != '']
        return i[1] if len(i) > 1 else None

    i = [x.strip() for x in i.split(',')]
    i = [x.lower() for x in i[0].split(' ') if x != '']
    if len(i) > 1 and i[1] in ('c', 'nc', 'z', 'nz', 'po', 'pe', 'p', 'm'):
        return i[1]

    return None


def single_registers(op):
    ''' Given a list of registers like ['a', 'bc', 'h', 'hl'] returns
    a set of single registers: ['a', 'b', 'c', 'h', 'l'].
    Non register parameters, like numbers will be ignored.
    '''
    result = set([])
    if isinstance(op, str):
        op = [op]

    for x in op:
        if is_8bit_register(x):
            result = result.union(set([x]))
        elif x == 'sp':
            result.add(x)
        elif x == 'af':
            result = result.union(['a', 'f'])
        elif x == "af'":
            result = result.union(["a'", "f'"])
        elif is_16bit_register(x):  # Must be a 16bit reg or we have an internal error!
            result = result.union(set([LO16(x), HI16(x)]))

    return list(result)


def result(i):
    ''' Returns which 8-bit registers are used by an asm
    instruction to return a result.
    '''
    ins = inst(i)
    op = oper(i)

    if ins in ('or', 'and') and op == ['a']:
        return ['f']

    if ins in ('xor', 'or', 'and', 'neg', 'cpl', 'daa', 'rld', 'rrd', 'rra', 'rla', 'rrca', 'rlca'):
        return ['a', 'f']

    if ins in ('bit', 'cp', 'scf', 'ccf'):
        return ['f']

    if ins in ('sub', 'add', 'sbc', 'adc'):
        if len(op) == 1:
            return ['a', 'f']
        else:
            return single_registers(op[0]) + ['f']

    if ins == 'djnz':
        return ['b', 'f']

    if ins in ['ldir', 'ldi', 'lddr', 'ldd']:
        return ['f', 'b', 'c', 'd', 'e', 'h', 'l']

    if ins in ['cpi', 'cpir', 'cpd', 'cpdr']:
        return ['f', 'b', 'c', 'h', 'l']

    if ins in ('pop', 'ld'):
        return single_registers(op[0])

    if ins in ('inc', 'dec', 'sbc', 'rr', 'rl', 'rrc', 'rlc'):
        return ['f'] + single_registers(op[0])

    if ins in ('set', 'res'):
        return single_registers(op[1])

    return []


# ------------------------------------------------------------------------------- #


class DuplicatedLabelError(Error):
    ''' Exception raised when a duplicated Label is found.
    This should never happen.
    '''

    def __init__(self, label):
        Error.__init__(self, "Invalid mnemonic '%s'" % label)
        self.label = label


class Registers(object):
    ''' A class storing registers value information.
    '''

    def __init__(self):
        self.reset()


    def reset(self):
        ''' Initial state
        '''
        self.regs = {}
        self.stack = []

        for i in 'abcdefhl':
            self.regs[i] = None  # Initial unknown state
            self.regs["%s'" % i] = None

        self.regs['ixh'] = None
        self.regs['ixl'] = None
        self.regs['iyh'] = None
        self.regs['iyl'] = None
        self.regs['sp'] = None
        self.regs['r'] = None
        self.regs['i'] = None

        self.regs['af'] = None
        self.regs['bc'] = None
        self.regs['de'] = None
        self.regs['hl'] = None

        self.regs['ix'] = None
        self.regs['iy'] = None

        self.regs["af'"] = None
        self.regs["bc'"] = None
        self.regs["de'"] = None
        self.regs["hl'"] = None

        self._16bit = {'b': 'bc', 'c': 'bc', 'd': 'de', 'e': 'de', 'h': 'hl', 'l': 'hl', \
                       "b'": "bc'", "c'": "bc'", "d'": "de'", "e'": "de'", "h'": "hl'", "l'": "hl'", \
                       'ixy': 'ix', 'ixl': 'ix', 'iyh': 'iy', 'iyl': 'iy'}

        self.C = self.Z = self.P = self.S = None


    def set(self, r, val):
        is_num = is_number(val)

        if is_num and self.getv(r) == valnum(val) & 0xFFFF:
            return  # The register already contains it value

        '''
        if self.get(r) is None and val is None:
            return # The register has already been destroyed
        '''

        if r == '(sp)':
            if self.stack == []:
                self.stack = [None]

            self.stack[-1] = str(valnum(val) & 0xFFFF) if is_num else val
            return

        if r[0] == '(':
            return

        if is_8bit_register(r):
            if is_register(val):
                self.regs[r] = self.regs[val]
                val = self.regs[val]
            else:
                if is_num:
                    oldval = self.getv(r)
                    val = str(valnum(val) & 0xFF)
                    if val == oldval:  # Does not change
                        return

                self.regs[r] = val

            # This change will reset any value related to this register
            for reg8 in list('abcdehl') + ['ixh', 'ixl', 'iyh', 'iyl', \
                                           "a'", "b'", "c'", "d'", "e'", "h'", "l'"]:
                tmp = self.regs[reg8]
                if tmp is None or is_number(tmp):
                    continue

                if tmp[0] == '(':  # (de), (hl), (ix+...), (
                    tmp = tmp[1:-1]

                if r in tmp:  # if other register depended on this
                    self.set(reg8, None)  # the cached info is deleted

            if r not in self._16bit.keys():
                return

            hl = self._16bit[r]
            if not is_num or not is_number(self.regs[hl]):
                self.regs[hl] = None  # unknown
                return

            val = int(val)
            if r in ('b', 'd', 'h', 'ixh', 'iyh', "b'", "d'", "h'"):  # high register
                self.regs[hl] = str((val << 8) + int(self.regs[LO16(hl)]))
                return

            self.regs[hl] = str((self.regs[HI16(hl)] << 8) + val)
            return

        # a 16 bit reg
        self.regs[r] = val

        if not is_num:
            self.regs[LO16(r)] = self.regs[HI16(r)] = None
        else:
            val = valnum(val)
            self.regs[LO16(r)] = val & 0xFF
            self.regs[HI16(r)] = val >> 8

        # This change will reset any value related to this register
        for reg16 in ('bc', 'de', 'hl', "bc'", "de'", "hl'", 'ix', 'iy'):
            tmp = self.regs[reg16]
            if tmp is None or is_number(tmp):
                continue

            if self.regs[reg16] == r:  # any register
                self.regs[reg16] = None
                self.set(LO16(reg16), None)  # Recursively destroys any register
                self.set(HI16(reg16), None)  # Depending on this one

        for reg8 in list('abcdehl') + ['ixh', 'ixl', 'iyh', 'iyl', \
                                       "a'", "b'", "c'", "d'", "e'", "h'", "l'"]:
            tmp = self.regs[reg8]
            if tmp is None or is_number(tmp):
                continue

            if tmp[0] == '(':  # (de), (hl), (ix+...), (
                tmp = tmp[0:2]

            if r[0] in tmp or r[1] in tmp:  # if other register depended on this
                self.set(reg8, None)  # the cached info is deleted
                # Flags ???
                # self.C = self.S = self.Z = self.P = None


    def get(self, r):
        ''' Returns precomputed value of the given expression
        '''
        r = r.lower()
        if r == '(sp)' and len(self.stack):
            return self.stack[-1]

        if is_number(r):
            return str(valnum(r))

        if not is_register(r):
            return None

        return self.regs[r]


    def getv(self, r):
        ''' Like the above, but returns the <int> value.
        '''
        v = self.get(r)
        if v is not None:
            try:
                v = int(v)
            except:
                v = None

        return v


    def eq(self, r1, r2):
        """ True if values of r1 and r2 registers are equal
        """
        if not is_register(r1) or not is_register(r2):
            return False

        if self.regs[r1] is None or self.regs[r2] is None:  # HINT: This's been never USED??
            return False

        return self.regs[r1] == self.regs[r2]


    def set_flag(self, val):
        if not is_number(val):
            self.regs['f'] = self.C = self.S = self.Z = self.P = None
            return

        self.set('f', val)
        val = valnum(val)
        self.C = val & 1
        self.P = (val >> 2) & 1
        self.Z = (val >> 6) & 1
        self.S = (val >> 7) & 1


    def inc(self, r):
        ''' Does inc on the register and precomputes flags
        '''
        if not is_register(r):
            self.set_flag(None)

            if r[0] == '(':
                for i in self.regs.keys():
                    if self.regs[i] == r:
                        self.set(i, None)
            return

        if self.getv(r) is not None:
            self.set(r, self.getv(r) + 1)
            return

        self.set(r, None)


    def dec(self, r):
        ''' Does dec on the register and precomputes flags
        '''
        if not is_register(r):
            self.set_flag(None)

            if r[0] == '(':
                for i in self.regs.keys():
                    if self.regs[i] == r:
                        self.set(i, None)
            return

        if self.getv(r) is not None:
            self.set(r, self.getv(r) - 1)
            return

        self.set(r, None)


    def rrc(self, r):
        ''' Does a ROTATION to the RIGHT |>>
        '''
        if self.regs[r] is None or isinstance(self.regs[r], str):
            self.set(r, None)
            self.set_flag(None)
            return

        self.regs[r] = (self.regs[r] >> 1) | ((self.regs[r] & 1) << 7)


    def rr(self, r):
        ''' Like the above, bus uses carry
        '''
        if self.C is None or self.regs[r] is None or isinstance(self.regs[r], str):
            self.set(r, None)
            self.set_flag(None)
            return

        self.rrc(r)
        tmp = self.C
        self.C = self.regs[r] >> 7
        self.regs[r] = (self.regs[r] & 0x7F) | (tmp << 7)


    def rlc(self, r):
        ''' Does a ROTATION to the LEFT <<|
        '''
        if self.regs[r] is None or isinstance(self.regs[r], str):
            self.set(r, None)
            self.set_flag(None)
            return

        self.set(r, ((self.regs[r] << 1) & 0xFF) | ((self.regs[r] & 1) >> 7))


    def rl(self, r):
        ''' Like the above, bus uses carry
        '''
        if self.C is None or self.regs[r] is None or isinstance(self.regs[r], str):
            self.set(r, None)
            self.set_flag(None)
            return

        self.rlc(r)
        tmp = self.C
        self.C = self.regs[r] & 1
        self.regs[r] = (self.regs[r] & 0xFE) | tmp


    def _is(self, r, val):
        ''' True if value of r is val.
        '''
        if not is_register(r):
            return False

        r = r.lower()

        if self.regs[r] is None:
            return False

        if is_register(val):
            if self.regs[val] is None:
                return False

            return self.regs[val] == self.regs[r]

        if is_number(val):
            val = str(valnum(val))

        return self.regs[r] == val


    def op(self, i, o):
        ''' Tries to update the registers values with the given
        instruction.
        '''
        for ii in range(len(o)):
            if is_register(o[ii]):
                o[ii] = o[ii].lower()

        if i == 'ld':
            self.set(o[0], o[1])
            return

        if i == 'push':
            if self.regs['sp'] is not None:
                if RE_IXIND.match(self.regs['sp']):
                    tmp = self.regs['sp'].lower()

                    if tmp in ('ix', 'iy'):
                        tmp += '-2'
                    else:
                        tmp = tmp[:2] + "%+i" % (int(tmp[2:]) - 2)

                    self.set('sp', tmp)
                elif valnum(self.regs['sp']):
                    self.set('sp', self.regs['sp'] - 2)
                else:
                    self.set('sp', None)

            self.stack += [self.regs[o[0]]]
            return

        if i == 'pop':
            if self.stack == []:
                self.set(o[0], None)
                return

            self.set(o[0], self.stack[-1])
            self.stack.pop()
            return

        if i in ('inc', 'dec'):
            r = o[0]

            if i == 'inc':
                self.inc(r)
            else:
                self.dec(r)

            if is_16bit_register(r):
                z = '(%s)' % r
                for i, v in zip(self.regs.keys(), self.regs.values()):
                    if v == r:  # Value == '(hl)' or (SP), (IX) ...
                        self.set(i, None)
                        # Since hl has changed, every (hl) instance must be deleted here.

                # inc/dec on 16bit regs does not affect flags
                return

            if self.getv(r) is None:
                self.set_flag(None)
                return

            self.Z = int(self.getv(r)) == 0
            return

        if i == 'rra':
            self.rr('a')
            return
        if i == 'rla':
            self.rl('a')
            return
        if i == 'rlca':
            self.rlc('a')
            return
        if i == 'rrca':
            self.rrc('a')
            return
        if i == 'rr':
            self.rr(o[0])
            return
        if i == 'rl':
            self.rl(o[0])
            return

        if i == 'exx':
            tmp = self.regs['bc']
            self.set('bc', "bc'")
            self.set("bc'", tmp)
            tmp = self.regs['de']
            self.set('de', "de'")
            self.set("de'", tmp)
            tmp = self.regs['hl']
            self.set('hl', "hl'")
            self.set("hl'", tmp)
            return

        if i == 'ex':
            tmp = self.get(o[1])
            self.set(o[1], o[0])
            self.set(o[0], tmp)
            return

        if i == 'xor':
            self.C = 0

            if o[0] == 'a':
                self.set('a', 0)
                self.Z = 1
                return

            if self.getv('a') is None or self.getv(o[0]) is None:
                self.Z = None
                self.set('a', None)
                return

            self.set('a', self.getv('a') ^ self.getv(o[0]))
            self.Z = int(self.get('a') == 0)
            return

        if i in ('or', 'and'):
            self.C = 0

            if self.getv('a') is None or self.getv(o[0]) is None:
                self.Z = None
                self.set('a', None)
                return

            if i == 'or':
                self.set('a', self.getv('a') | self.getv(o[0]))
            else:
                self.set('a', self.getv('a') & self.getv(o[0]))

            self.Z = int(self.get('a') == 0)
            return

        if i in ('adc', 'sbc'):
            if len(o) == 1:
                o = ['a', o[0]]

            if self.C is None:
                self.set(o[0], 'None')
                self.Z = None
                self.set(o[0], None)
                return

            if i == 'sbc' and o[0] == o[1]:
                self.Z = int(not self.C)
                self.set(o[0], -self.C)
                return

            if self.getv(o[0]) is None or self.getv(o[1]) is None:
                self.set_flag(None)
                self.set(o[0], None)
                return

            if i == 'adc':
                val = self.getv(o[0]) + self.getv(o[1]) + self.C
                if is_8bit_register(o[0]):
                    self.C = int(val > 0xFF)
                else:
                    self.C = int(val > 0xFFFF)
                self.set(o[0], val)
                return

            val = self.getv(o[0]) - self.getv(o[1]) - self.C
            self.C = int(val < 0)
            self.Z = int(val == 0)
            self.set(o[0], val)
            return

        if i in ('add', 'sub'):
            if len(o) == 1:
                o = ['a', o[0]]

            if i == 'sub' and o[0] == o[1]:
                self.Z = 1
                self.C = 0
                self.set(o[0], 0)
                return

            if not is_number(self.get(o[0])) or not is_number(self.get(o[1])) is None:
                self.set_flag(None)
                self.set(o[0], None)
                return

            if i == 'add':
                val = self.getv(o[0]) + self.getv(o[1])
                if is_8bit_register(o[0]):
                    self.C = int(val > 0xFF)
                    val &= 0xFF
                    self.Z = int(val == 0)
                    self.S = val >> 7
                else:
                    self.C = int(val > 0xFFFF)
                    val &= 0xFFFF

                self.set(o[0], val)
                return

            val = self.getv(o[0]) - self.getv(o[1])
            if is_8bit_register(o[0]):
                self.C = int(val < 0)
                val &= 0xFF
                self.Z = int(val == 0)
                self.S = val >> 7
            else:
                self.C = int(val < 0)
                val &= 0xFFFF

            self.set(o[0], val)
            return

        if i == 'neg':
            if self.getv('a') is None:
                self.set_flag(None)
                return

            val = -self.getv('a')
            self.set('a', val)
            self.Z = int(not val)
            val &= 0xFF
            self.S = val >> 7
            return

        if i == 'scf':
            self.C = 1
            return

        if i == 'ccf':
            if self.C is not None:
                self.C = int(not self.C)
            return

        if i == 'cpl':
            if self.getv('a') is None:
                return

            self.set('a', 0xFF ^ self.getv('a'))
            return

        # Unknown. Resets ALL
        self.reset()


class MemCell(object):
    ''' Class describing a memory address.
    It just contains the addr (memory array index), and
    the instruction.
    '''

    def __init__(self, instr, addr):
        self.addr = addr
        self.__instr = instr.strip()


    def __get_asm(self):
        return self.__instr


    def __set_asm(self, value):
        self.__instr = value

    asm = property(__get_asm, __set_asm)

    @property
    def is_label(self):
        ''' Returns whether the current addr
        contains a label.
        '''
        return self.__instr[-1] == ':'


    @property
    def is_ender(self):
        ''' Returns if this instruction is a BLOCK ender
        '''
        return inst(self.__instr) in BLOCK_ENDERS


    @property
    def inst(self):
        ''' Returns just the asm instruction in lower
        case. E.g. 'ld', 'jp', 'pop'
        '''
        if self.is_label:
            return self.__instr[:-1]

        return inst(self.__instr)


    @property
    def condition_flag(self):
        ''' Returns the flag this instrunction uses
        or None. E.g. 'c' for Carry, 'nz' for not-zero, etc.
        That is the condition required for this instruction
        to execute. For example: ADC A, 0 does NOT have a
        condition flag (it always execute) whilst RETC does.
        '''
        return condition(self.asm)


    @property
    def opers(self):
        ''' Returns a list of operators this mnemonic uses
        '''
        i = [x for x in self.asm.strip(' \t\n').split(' ') if x != '']

        if len(i) == 1:
            return []

        i = ''.join(i[1:]).split(',')
        if self.condition_flag is not None:
            i = i[1:]
        else:
            i = i[0:]

        op = [x.lower() if is_register(x) else x for x in i]
        return op


    @property
    def destroys(self):
        ''' Returns which single registers (including f, flag)
        this instruction changes.

        Registers are: a, b, c, d, e, i, h, l, ixh, ixl, iyh, iyl, r

        LD a, X => Destroys a
        LD a, a => Destroys nothing

        INC a => Destroys a, f
        POP af => Destroys a, f, sp
        PUSH af => Destroys sp

        ret => Destroys SP
        '''
        res = set([])
        i = self.inst
        o = self.opers

        if i in ('push', 'ret', 'call', 'rst'):
            return ['sp']

        if i in ('pop'):
            res.add('sp')

        res = res.union(result(self.asm))
        return list(res)


    @property
    def requires(self):
        ''' Returns the registers, operands, etc. required by an instruction.
        '''
        result = set([])
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

        elif i in ['rra', 'rla', 'rrca', 'rlca']:
            result.add('a')
            result.add('f')

        elif i in ['xor', 'cp']:
            # XOR A, and CP A don't need the a register
            if o[0] != 'a':
                result.add('a')

                if o[0][0] != '(' and not is_number(o[0]):
                    result = result.union(single_registers(o))

        elif i in ['or', 'and']:
            # AND A, and OR A do need the a register
            result.add('a')

            if o[0][0] != '(' and not is_number(o[0]):
                result = result.union(single_registers(o))

        elif i in ['adc', 'sbc', 'add', 'sub']:
            if len(o) == 1:
                if i not in ('sub', 'sbc') or o[0] != 'a':
                    # sbc a and sub a dont' need the a register
                    result.add('a')

                if o[0][0] != '(' and not is_number(o[0]):
                    result = result.union(single_registers(o))
            else:
                if o[0] != o[1] or i in ('add', 'adc'):
                    # sub HL, HL or sub X, X don't need the X register(s)
                    result = result.union(single_registers(o))

            if i in ['adc', 'sbc']:
                result.add('f')

        elif i in ['daa', 'rld', 'rrd', 'neg', 'cpl']:
            result.add('a')

        elif i in ['rl', 'rr', 'rlc', 'rrc']:
            result = result.union(single_registers(o) + ['f'])

        elif i in ['sla', 'sll', 'sra', 'srl', 'inc', 'dec']:
            result = result.union(single_registers(o))

        elif i == 'djnz':
            result.add('b')

        elif i in ['ldir', 'lddr', 'ldi', 'ldd']:
            result = result.union(['b', 'c', 'd', 'e', 'h', 'l'])

        elif i in ['cpi', 'cpd', 'cpir', 'cpdr']:
            result = result.union(['a', 'b', 'c', 'h', 'l'])

        elif i == 'ld' and not is_number(o[1]):
            result = result.union(single_registers(o[1]))

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
            result = result.union(single_registers(o))

        elif i in ['bit', 'set', 'res']:
            result = result.union(single_registers(o[1]))

        elif i == 'out':
            result.add(o[1])
            if o[0] == '(c)':
                result.add('c')

        elif i == 'in':
            if o[1] == '(c)':
                result.add('c')

        elif i == 'im':
            result.add('i')

        result = list(result)
        return result


    def affects(self, reglist):
        ''' Returns if this instruction affects any of the registers
        in reglist.
        '''
        if isinstance(reglist, str):
            reglist = [reglist]

        reglist = single_registers(reglist)

        return len([x for x in self.destroys if x in reglist]) > 0


    def needs(self, reglist):
        ''' Returns if this instruction need any of the registers
        in reglist.
        '''
        if isinstance(reglist, str):
            reglist = [reglist]

        reglist = single_registers(reglist)

        return len([x for x in self.requires if x in reglist]) > 0


    @property
    def used_labels(self):
        ''' Returns a list of required labels for this instruction
        '''
        result = []

        tmp = self.asm.strip(' \n\r\t')
        if not len(tmp) or tmp[0] in ('#', ';'):
            return result

        try:
            tmpLexer = asmlex.lex.lex(object=asmlex.Lexer(), lextab='zxbasmlextab')
            tmpLexer.input(tmp)

            while True:
                token = tmpLexer.token()
                if not token:
                    break

                if token.type == 'ID':
                    result += [token.value]
        except:
            pass

        return result


    def replace_label(self, oldLabel, newLabel):
        ''' Replaces old label with a new one
        '''
        if oldLabel == newLabel:
            return

        tmp = re.compile(r'\b' + oldLabel + r'\b')
        last = 0
        l = len(newLabel)
        while True:
            match = tmp.search(self.asm[last:])
            if not match:
                break

            txt = self.asm
            self.asm = txt[:last + match.start()] + newLabel + txt[last + match.end():]
            last += match.start() + l


class LabelInfo(object):
    ''' Class describing label information
    '''

    def __init__(self, label, addr, basic_block=None):
        ''' Stores the label name, the address counter into memory (rather useless)
        and which basic block contains it.
        '''
        self.label = label
        self.addr = addr
        self.basic_block = basic_block
        self.used_by = IdentitySet()  # Which BB uses this label, if any

        if label in LABELS.keys():
            raise DuplicatedLabelError(label)


class BasicBlock(object):
    ''' A Class describing a basic block
    '''

    def __init__(self, memory):
        ''' Initializes the internal array of instructions.
        '''
        self.mem = []
        for x in range(len(memory)):
            self.mem += [MemCell(memory[x], x)]

        self.asm = memory
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
        ''' Returns a t-uple containing labels within this block
        '''
        return [cell.inst for cell in self.mem if cell.is_label]


    @property
    def is_partitionable(self):
        ''' Returns if this block can be partitiones in 2 or more blocks,
        because if contains enders.
        '''
        if len(self.mem) < 2: return False  # An atomic block

        for i in range(len(self) - 1):
            if self.mem[i].is_ender:
                return True

        for label in JUMP_LABELS:
            if LABELS[label].basic_block == self and (not self.mem[0].is_label or self.mem[0].inst != label):
                return True

        return False


    def update_labels(self):
        ''' Update global labels table so they point to the current block
        '''
        for l in self.labels:
            LABELS[l].basic_block = self


    def delete_from(self, basic_block):
        ''' Removes the basic_block ptr from the list for "comes_from"
        if it exists. It also sets self.prev to None if it is basic_block.
        '''
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
        ''' Removes the basic_block ptr from the list for "goes_to"
        if it exists. It also sets self.next to None if it is basic_block.
        '''
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
        ''' This simulates a set. Adds the basic_block to the comes_from
        list if not done already.
        '''
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
        ''' This simulates a set. Adds the basic_block to the goes_to
        list if not done already.
        '''
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
        ''' If the last instruction of this block is a JP, JR or RET (with no
        conditions) then the next and goes_to sets just contains a
        single block
        '''
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
        ''' Every label has a set containing
        which blocks jumps (jp, jr, call) if any.
        A block can "use" (call/jump) only another block
        and only one'''

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
        ''' Once the block is a Basic one, check the last instruction and updates
        goes_to and comes_from set of the receivers.
        Note: jp, jr and ret are already done in update_next_block()
        '''
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
        ''' Checks whether any of the given regs are required from the given point
        to the end or not.
        '''
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

            if regs == []:
                return False

        self.lock = True
        result = self.goes_requires(regs)
        self.lock = False

        return result


    def requires(self, i=0):
        ''' Returns a list of registers and variables this block requires.
        By default checks from the beginning (i = 0).
        '''
        regs = ['a', 'b', 'c', 'd', 'e', 'h', 'l', 'i', 'ixh', 'ixl', 'iyh', 'iyl', 'sp']
        top = len(self)
        result = []

        for ii in range(i, top):
            for r in self.mem[ii].requires:
                r = r.lower()
                if r in regs:
                    result += [r]
                    regs.remove(r)

            for r in self.mem[ii].destroys:
                r = r.lower()
                if r in regs:
                    regs.remove(r)

            if regs == []:
                break

        return result


    def destroys(self, i=0):
        ''' Returns a list of registers this block destroys
        By default checks from the beginning (i = 0).
        '''
        regs = ['a', 'b', 'c', 'd', 'e', 'h', 'l', 'i', 'ixh', 'ixl', 'iyh', 'iyl', 'sp']
        top = len(self)
        result = []

        for ii in range(i, top):
            for r in self.mem[ii].destroys:
                if r in regs:
                    result += [r]
                    regs.remove(r)
                    break

            if regs == []:
                break

        return result


    def swap(self, a, b):
        ''' Swaps mem positions a and b
        '''
        self.mem[a], self.mem[b] = self.mem[b], self.mem[a]
        self.asm[a], self.asm[b] = self.asm[b], self.asm[a]


    def goes_requires(self, regs):
        ''' Returns whether any of the goes_to block requires any of
        the given registers.
        '''
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
        ''' Returns the index of a label.
        Returns None if not found.
        '''
        for i in range(len(self)):
            if self.mem[i].is_label and self.mem[i].inst == label:
                return i

        return None


    def get_first_non_label_instruction(self):
        ''' Returns the memcell of the given block, which is
        not a LABEL.
        '''
        for i in range(len(self)):
            if not self.mem[i].is_label:
                return self.mem[i]

        return None


    def optimize(self):
        ''' Tries to detect peep-hole patterns in this basic block
        and remove them.
        '''
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
                if self.mem[i].is_label:
                    # ignore labels
                    continue

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

                    if OPT07 and i0 == 'ld' and i2 == 'ld' and o2[1] == 'hl' and not self.is_used(['h', 'l'], i + 2) and \
                            (o0[0] == 'h' and o0[1] == 'b' and o1[0] == 'l' and o1[1] == 'c' or \
                                                     o0[0] == 'l' and o0[1] == 'c' and o1[0] == 'h' and o1[1] == 'b' or \
                                                     o0[0] == 'h' and o0[1] == 'd' and o1[0] == 'l' and o1[1] == 'e' or \
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
                            (o1[1] == 'h' and o1[0] == 'b' and o2[1] == 'l' and o2[0] == 'c' or \
                                                     o1[1] == 'l' and o1[0] == 'c' and o2[1] == 'h' and o2[0] == 'b' or \
                                                     o1[1] == 'h' and o1[0] == 'd' and o2[1] == 'l' and o2[0] == 'e' or \
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
                            (o1[1] == 'h' and o1[0] == 'b' and o2[1] == 'l' and o2[0] == 'c' or \
                                                     o1[1] == 'l' and o1[0] == 'c' and o2[1] == 'h' and o2[0] == 'b' or \
                                                     o1[1] == 'h' and o1[0] == 'd' and o2[1] == 'l' and o2[0] == 'e' or \
                                                     o1[1] == 'l' and o1[0] == 'e' and o2[1] == 'h' and o2[
                                         0] == 'd') and \
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
                                # { LD A, (IX + n); [ DEC A | INC A ]; LD (X), A} ::= { [ DEC (IX + n) | INC (IX + n) ] }
                                tmp = str(self.asm)
                                self.pop(i + 1)
                                self.pop(i)
                                self[i - 1] = '%s %s' % (i1, o0[1])
                                changed = True
                                __DEBUG__('Changed %s ==> %s' % (tmp, self.asm), 2)
                                break

                if OPT11 and i0 == 'push' and i3 == 'pop' and o0[0] != o3[0] \
                        and o0[0] in ('hl', 'de') and o3[0] in ('hl', 'de') \
                        and i1 == i2 == 'ld' and ( \
                                            o1[0] == HI16(o0[0]) and o2[0] == LO16(o0[0]) and o1[1] == HI16(o3[0]) and
                                    o2[1] == LO16(o3[0]) or \
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
                        not self.mem[i - 1].affects([o1[0], 'sp']) and not self.mem[i - 1].needs([o1[0], 'sp']):
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
                        # { LD DE, (X2) ; LD BC, (X1); PUSH DE; PUSH BC } ::= { LD HL, (X2); PUSH HL; LD HL, (X1); PUSH HL }
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
                    if OPT20 and ii1 in ('jp', 'jr') and (cc is None or \
                                                                      cc == c or \
                                                                          cc == 'c' and regs.C == 1 or \
                                                                          cc == 'z' and regs.Z == 1 or \
                                                                          cc == 'nc' and regs.C == 0 or \
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

                regs.op(i1, o1)


class DummyBasicBlock(BasicBlock):
    ''' A dummy basic block with some basic information
    about what registers uses an destroys
    '''

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
    ''' Returns two blocks, as a result of partitioning the given one at
    i-th instruction.
    '''
    i += 1
    new_block = BasicBlock(block.asm[i:])
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

    return (block, new_block)


def partition_block(block):
    ''' If a block is not partitionable, returns a list with the same block.
    Otherwise, returns a list with the resulting blocks, recursively.
    '''
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


def flatten_list(x):
    result = []

    for l in x:
        if not isinstance(l, list):
            result += [l]
        else:
            result += flatten_list(l)

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
    ''' Traverses memory, to annotate all the labels in the global
    LABELS table
    '''
    for cell in MEMORY:
        if cell.is_label:
            label = cell.inst
            LABELS[label] = LabelInfo(label, cell.addr, basic_block)  # Stores it globally


def initialize_memory(basic_block):
    ''' Initializes global memory array with the given one
    '''
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
    ''' Cleans up initial memory. Each label must be
    ALONE. Each instruction must have an space, etc...
    '''
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

    # TODO: Removed. Find out why this is needed
    # Now checks for every parenthesis to have spaces on the innerside
    # RE_LP = re.compile(r'[^ ]\(')
    #
    # i = 0
    # while i < len(initial_memory):
    #     tmp = initial_memory[i]
    #     match = RE_LP.search(tmp)
    #     if not match:
    #         i += 1
    #         continue
    #
    #     j = match.start() + 1
    #     tmp = tmp[:j] + ' ' + tmp[j:]
    #     initial_memory[i] = tmp
    #     i += 1


def cleanup_local_labels(block):
    ''' Traverses memory, to make any local label a unique
    global one. At this point there's only a single code
    block
    '''
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

        tmp = cell.asm.strip()
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
        if MEMORY[i].asm[0] == ';':
            MEMORY.pop(i)

    block.mem = MEMORY
    block.asm = [x.asm for x in MEMORY if len(x.asm.strip())]


def optimize(initial_memory):
    ''' This will remove useless instructions
    '''
    global BLOCKS

    cleanupmem(initial_memory)
    if OPTIONS.optimization.value <= 2:
        return '\n'.join(initial_memory)

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

    for x in basic_blocks:
        x.optimize()

    for x in basic_blocks:
        if x.comes_from == [] and len([y for y in JUMP_LABELS if x is LABELS[y].basic_block]):
            x.ignored = True

    return '\n'.join(flatten_list([x.asm for x in basic_blocks if not x.ignored]))


