# -*- coding: utf-8 -*-

from collections import defaultdict
from . import asm

from .helpers import new_tmp_val, new_tmp_val16, HI16, LO16, HL_SEP
from .helpers import is_unknown, is_unknown16, valnum, is_number
from .helpers import is_register, is_8bit_oper_register, is_16bit_composed_register
from .helpers import get_L_from_unknown_value, idx_args, LO16_val


class Flags(object):
    def __init__(self):
        self.C = None
        self.Z = None
        self.P = None
        self.S = None


class CPUState(object):
    """ A class storing registers value information (CPU State).
    """
    def __init__(self):
        self.regs = None
        self.stack = None
        self.mem = None
        self._flags = None
        self._16bit = None
        self.reset()

    @property
    def Z(self):
        """ The Z flag
        """
        return self._flags[0].Z

    @Z.setter
    def Z(self, val):
        """ Sets the Z flag, and tries to update the F register accordingly.
        If the F register is unknown, sets it with a new unknown value.
        """
        assert is_unknown(val) or val in (0, 1)
        self._flags[0].Z = val
        if not is_unknown(val) and is_number(self.regs['f']):
            self.regs['f'] = str((self.getv('f') & 0xBF) | (val << 6))
        else:
            self.regs['f'] = new_tmp_val()

    @property
    def C(self):
        """ The C flag
        """
        return self._flags[0].C

    @C.setter
    def C(self, val):
        """ Sets the C flag, and tries to update the F register accordingly.
        If the F register is unknown, sets it with a new unknown value.
        """
        assert is_unknown(val) or val in (0, 1)
        self._flags[0].C = val
        if not is_unknown(val) and is_number(self.regs['f']):
            self.regs['f'] = str((self.getv('f') & 0xFE) | val)
        else:
            self.regs['f'] = new_tmp_val()

    @property
    def P(self):
        """ The P flag
        """
        return self._flags[0].P

    @P.setter
    def P(self, val):
        """ Sets the P flag, and tries to update the F register accordingly.
        If the F register is unknown, sets it with a new unknown value.
        """
        assert is_unknown(val) or val in (0, 1)
        self._flags[0].P = val
        if not is_unknown(val) and is_number(self.regs['f']):
            self.regs['f'] = str((self.getv('f') & 0xFB) | (val << 2))
        else:
            self.regs['f'] = new_tmp_val()

    @property
    def S(self):
        """ The S flag
        """
        return self._flags[0].S

    @S.setter
    def S(self, val):
        """ Sets the S flag, and tries to update the F register accordingly.
        If the F register is unknown, sets it with a new unknown value.
        """
        assert is_unknown(val) or val in (0, 1)
        self._flags[0].S = val
        if not is_unknown(val) and is_number(self.regs['f']):
            self.regs['f'] = str((self.getv('f') & 0x7F) | (val << 7))
        else:
            self.regs['f'] = new_tmp_val()

    def reset(self, regs=None, mems=None):
        """ Initial state
        """
        if regs is None:
            regs = {}

        if mems is None:
            mems = {}

        self.regs = {}
        self.stack = []
        self.mem = defaultdict(new_tmp_val16)  # Dict of label -> value in memory
        self._flags = [Flags(), Flags()]

        # # Memory for IX / IY accesses
        self.ix_ptr = set()

        for i in 'abcdefhl':
            self.regs[i] = new_tmp_val()  # Initial unknown state
            self.regs["%s'" % i] = new_tmp_val()

        self.regs['ixh'] = new_tmp_val()
        self.regs['ixl'] = new_tmp_val()
        self.regs['iyh'] = new_tmp_val()
        self.regs['iyl'] = new_tmp_val()
        self.regs['sp'] = new_tmp_val()
        self.regs['r'] = new_tmp_val()
        self.regs['i'] = new_tmp_val()

        for i in 'af', 'bc', 'de', 'hl':
            self.regs[i] = '{}{}{}'.format(self.regs[i[0]], HL_SEP, self.regs[i[1]])
            self.regs["%s'" % i] = '{}{}{}'.format(self.regs["%s'" % i[0]], HL_SEP, self.regs["%s'" % i[1]])

        self.regs['ix'] = '{}{}{}'.format(self.regs['ixh'], HL_SEP, self.regs['ixl'])
        self.regs['iy'] = '{}{}{}'.format(self.regs['iyh'], HL_SEP, self.regs['iyl'])

        self._16bit = {'b': 'bc', 'c': 'bc', 'd': 'de', 'e': 'de', 'h': 'hl', 'l': 'hl',
                       "b'": "bc'", "c'": "bc'", "d'": "de'", "e'": "de'", "h'": "hl'", "l'": "hl'",
                       'ixy': 'ix', 'ixl': 'ix', 'iyh': 'iy', 'iyl': 'iy', 'a': 'af', "a'": "af'",
                       'f': 'af', "f'": "af'"}

        self.regs.update(**regs)
        self.mem.update(**mems)

        for key_ in mems:
            idx = idx_args(key_)
            if idx:
                self.ix_ptr.add(idx)

        self.reset_flags()

    def reset_flags(self):
        """ Resets flags to an "unknown state"
        """
        self.C = None
        self.Z = None
        self.P = None
        self.S = None

    def clear_idx_reg_refs(self, r):
        """ For the given ix/iy, remove all references of it in memory, which are not in the form
        ix/iy +/- n
        """
        r = r.lower()
        assert r in ('ix', 'iy')

        for k in list(self.ix_ptr):
            if k[0] != r:
                continue

            if not is_number(k[2]):
                del self.mem['{}{}{}'.format(*k)]
                self.ix_ptr.remove(k)

    def shift_idx_regs_refs(self, r, offset):
        """ Given an idx register r (ix / iy) and an offset, all the references in memory
        will be shifted the given amount.
        I.e. for 'ix', 1
            (ix + 1) will contain (ix + 2), and so on.
            (ix + 127) will contain an unknown8 value

        The same applies for negative offsets. For iy - 2
            (iy + 2) will contain current (iy + 0)
            (iy - 126) and lower will contain random unknown8
        """
        if offset == 0:
            return

        self.clear_idx_reg_refs(r)
        r = r.lower()
        if offset > 0:
            for i in range(-128, 128):
                idx = '%s%+i' % (r, i)
                old_idx = '%s%+i' % (r, offset + i)
                self.mem[idx] = new_tmp_val() if offset + i > 127 else self.mem[old_idx]
        else:
            for i in range(127, -129, -1):
                idx = '%s%+i' % (r, i)
                old_idx = '%s%+i' % (r, offset + i)
                self.mem[idx] = new_tmp_val() if offset + i < -128 else self.mem[old_idx]

    def set(self, r, val):
        val = self.get(val)
        is_num = is_number(val)

        if val is None:
            val = new_tmp_val16()
        else:
            val = str(val)

        if is_num:
            val = str(valnum(val) & 0xFFFF)

        if self.getv(r) == val:
            return  # The register already contains this

        if r == '(sp)':
            if not self.stack:
                self.stack = [new_tmp_val16()]

            self.stack[-1] = val
            return

        if r in {'(hl)', '(bc)', '(de)'}:  # ld (bc|de|hl), val
            r = self.regs[r[1:-1]]
            if r in self.mem and val == self.mem[r]:
                return  # Already set

            self.mem[r] = val
            return

        if r[0] == '(':  # (mem) <- r  => store in memory address
            r = r[1:-1].strip()
            idx = idx_args(r)
            if idx is not None:
                r = "{}{}{}".format(*idx)
                self.ix_ptr.add(idx)
                val = LO16_val(val)

            if r in self.mem and val == self.mem[r]:
                return  # the same value to the same pos does nothing... (strong assumption: NON-VOLATILE)
            self.mem[r] = val
            return

        if is_8bit_oper_register(r):
            oldval = self.getv(r)
            if is_num:
                val = str(valnum(val) & 0xFF)
            else:
                val = get_L_from_unknown_value(val)

            if val == oldval:  # Does not change
                return

            self.regs[r] = val
            if r not in self._16bit:
                return

            hl = self._16bit[r]
            h_ = self.regs[hl[0]]
            l_ = self.regs[hl[1]]
            if is_number(h_) and is_number(l_):
                self.regs[hl] = str((valnum(h_) << 8) | valnum(l_))
                return

            self.regs[hl] = '{}{}{}'.format(h_, HL_SEP, l_)
            return

        # a 16 bit reg
        assert r in self.regs
        assert is_num or is_unknown16(val), "val '{}' is not a number nor an unknown16".format(val)

        self.regs[r] = val
        if is_16bit_composed_register(r):  # sp register is not included. Special case
            if not is_num:
                self.regs[HI16(r)], self.regs[LO16(r)] = val.split(HL_SEP)
            else:
                val = valnum(val)
                self.regs[HI16(r)], self.regs[LO16(r)] = str(val >> 8), str(val & 0xFF)

            if 'f' in r:
                self.reset_flags()

    def get(self, r):
        """ Returns precomputed value of the given expression
        """
        if r is None:
            return None

        r = str(r)

        if r.lower() == '(sp)' and self.stack:
            return self.stack[-1]

        if r.lower() in {'(hl)', '(bc)', '(de)'}:
            i = self.regs[r.lower()[1:-1]]
            return self.mem[i]

        if r[:1] == '(':
            v_ = r[1:-1].strip()
            idx = idx_args(v_)
            if idx is not None:
                v_ = "{}{}{}".format(*idx)
                self.ix_ptr.add(idx)

            val = self.mem[v_]
            if idx is not None:
                self.mem[v_] = val = LO16_val(val)

            return val

        if is_number(r):
            return str(valnum(r))

        if is_unknown(r):
            return r

        r = r.lower()
        if not is_register(r):
            return None

        return self.regs[r]

    def getv(self, r):
        """ Like the above, but returns the <int> value or None.
        """
        v = self.get(r)
        if not is_unknown(v):
            try:
                v = int(v)
            except ValueError:
                v = None
        else:
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
            self.regs['f'] = new_tmp_val()
            self.reset_flags()
            return

        self.set('f', val)
        val = valnum(val)
        self.C = val & 1
        self.P = (val >> 2) & 1
        self.Z = (val >> 6) & 1
        self.S = (val >> 7) & 1

    def inc(self, r):
        """ Does inc on the register and precomputes flags
        """
        if not is_register(r):
            if r[0] == '(':  # a memory position, basically: inc(hl)
                r_ = r[1:-1].strip()
                v_ = self.getv(self.mem.get(r_, None))
                if v_ is not None:
                    v_ = (v_ + 1) & 0xFF
                    self.mem[r_] = str(v_)
                    self.Z = int(v_ == 0)  # HINT: This might be improved
                    self.C = int(v_ == 0)
                else:
                    self.mem[r_] = new_tmp_val()
            return

        if self.getv(r) is not None:
            self.set(r, self.getv(r) + 1)
        else:
            self.set(r, None)

        if r in ('ix', 'iy'):
            self.shift_idx_regs_refs(r, 1)

        if not is_8bit_oper_register(r):  # INC does not affect flag for 16bit regs
            return

        if is_unknown(self.regs[r]):
            self.set_flag(None)
            return

        v_ = self.getv(r)
        self.Z = int(v_ == 0)
        self.C = int(v_ == 0)

    def dec(self, r):
        """ Does dec on the register and precomputes flags
        """
        if not is_register(r):
            if r[0] == '(':  # a memory position, basically: inc(hl)
                r_ = r[1:-1].strip()
                v_ = self.getv(self.mem.get(r_, None))
                if v_ is not None:
                    v_ = (v_ - 1) & 0xFF
                    self.mem[r_] = str(v_)
                    self.Z = int(v_ == 0)  # HINT: This might be improved
                    self.C = int(v_ == 0xFF)
                else:
                    self.mem[r_] = new_tmp_val()
            return

        if self.getv(r) is not None:
            self.set(r, self.getv(r) - 1)
        else:
            self.set(r, None)

        if r in ('ix', 'iy'):
            self.shift_idx_regs_refs(r, -1)

        if not is_8bit_oper_register(r):  # DEC does not affect flag for 16bit regs
            return

        if is_unknown(self.regs[r]):
            self.set_flag(None)
            return

        v_ = self.getv(r)
        self.Z = int(v_ == 0)
        self.C = int(v_ == 0xFF)

    def rrc(self, r):
        """ Does a ROTATION to the RIGHT |>>
        """
        if not is_number(self.regs[r]):
            self.set(r, None)
            self.set_flag(None)
            return

        v_ = self.getv(self.regs[r]) & 0xFF
        self.regs[r] = str((v_ >> 1) | ((v_ & 1) << 7))

    def rr(self, r):
        """ Like the above, bus uses carry
        """
        if self.C is None or not is_number(self.regs[r]):
            self.set(r, None)
            self.set_flag(None)
            return

        self.rrc(r)
        tmp = self.C
        v_ = self.getv(self.regs[r])
        self.C = v_ >> 7
        self.regs[r] = str((v_ & 0x7F) | (tmp << 7))

    def rlc(self, r):
        """ Does a ROTATION to the LEFT <<|
        """
        if not is_number(self.regs[r]):
            self.set(r, None)
            self.set_flag(None)
            return

        v_ = self.getv(self.regs[r]) & 0xFF
        self.set(r, ((v_ << 1) & 0xFF) | (v_ >> 7))

    def rl(self, r):
        """ Like the above, bus uses carry
        """
        if self.C is None or not is_number(self.regs[r]):
            self.set(r, None)
            self.set_flag(None)
            return

        self.rlc(r)
        tmp = self.C
        v_ = self.getv(self.regs[r])
        self.C = v_ & 1
        self.regs[r] = str((v_ & 0xFE) | tmp)

    def _is(self, r, val):
        """ True if value of r is val.
        """
        if not is_register(r) or val is None:
            return False

        r = r.lower()
        if is_register(val):
            return self.eq(r, val)

        if is_number(val):
            val = str(valnum(val))
        else:
            val = str(val)

        if val[0] == '(':
            val = self.mem[val[1:-1]]

        return self.regs[r] == val

    def execute(self, asm_code):
        """ Tries to update the registers values with the given
        asm line.
        """
        asm_ = asm.Asm(asm_code)
        if asm_.is_label:
            return

        i = asm_.inst
        o = asm_.oper

        for ii in range(len(o)):
            if is_register(o[ii]):
                o[ii] = o[ii].lower()

        if i == 'ld':
            self.set(o[0], o[1])
            return

        if i == 'push':
            if valnum(self.regs['sp']) is not None:
                self.set('sp', (self.getv(self.regs['sp']) - 2) % 0xFFFF)
            else:
                self.set('sp', None)
            self.stack.append(self.regs[o[0]])
            return

        if i == 'pop':
            self.set(o[0], self.stack and self.stack.pop() or None)
            if valnum(self.regs['sp']):
                self.set('sp', (self.getv(self.regs['sp']) + 2) % 0xFFFF)
            else:
                self.set('sp', None)
            return

        if i == 'inc':
            self.inc(o[0])
            return

        if i == 'dec':
            self.dec(o[0])
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
            for j in 'bc', 'de', 'hl', 'b', 'c', 'd', 'e', 'h', 'l':
                self.regs[j], self.regs["%s'" % j] = self.regs["%s'" % j], self.regs[j]
            return

        if i == 'ex':
            if o == ['de', 'hl']:
                for a, b in [('de', 'hl'), ('d', 'h'), ('e', 'l')]:
                    self.regs[a], self.regs[b] = self.regs[b], self.regs[a]
            else:
                for j in 'af', 'a', 'f':
                    self.regs[j], self.regs["%s'" % j] = self.regs["%s'" % j], self.regs[j]
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
                if is_8bit_oper_register(o[0]):
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
                if is_8bit_oper_register(o[0]):
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
            if is_8bit_oper_register(o[0]):
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
            self.C = int(not self.Z)
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
                self.set('a', None)
                return

            self.set('a', 0xFF ^ self.getv('a'))
            return

        if i == 'cp':
            val = self.getv(o[0])
            if not is_number(self.regs['a']) or is_unknown(val):
                self.set_flag(None)
                return

            val = int(self.regs['a']) - val
            self.Z = int(val == 0)
            self.C = int(val < 0)
            self.S = int(val < 0)
            return

        if i in {'jp', 'jr', 'ret', 'rst', 'call'}:
            return

        if i == 'djnz':
            if self.getv('b') is None:
                self.set('b', None)
                self.Z = None
                return

            val = (self.getv('b') - 1) & 0xFF
            self.set('b', val)
            self.Z = int(val == 0)
            return

        if i == 'out':
            return

        if i == 'in':
            self.set(o[0], None)
            return

        # Unknown. Resets ALL
        self.reset()

    def __repr__(self):
        return '\n'.join('{}: {}'.format(x, y) for x, y in self.regs.items())
