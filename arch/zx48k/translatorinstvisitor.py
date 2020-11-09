# -*- coding: utf-8 -*-

from src.api.constants import TYPE
from src import symbols

from src.ast import NodeVisitor
from .backend import Quad, MEMORY
from src.api.debug import __DEBUG__


class TranslatorInstVisitor(NodeVisitor):
    @staticmethod
    def emit(*args):
        """ Convert the given args to a Quad (3 address code) instruction
        """
        quad = Quad(*args)
        __DEBUG__('EMIT ' + str(quad))
        MEMORY.append(quad)

    @staticmethod
    def TSUFFIX(type_):
        assert isinstance(type_, symbols.TYPE) or TYPE.is_valid(type_)

        _TSUFFIX = {TYPE.byte_: 'i8', TYPE.ubyte: 'u8',
                    TYPE.integer: 'i16', TYPE.uinteger: 'u16',
                    TYPE.long_: 'i32', TYPE.ulong: 'u32',
                    TYPE.fixed: 'f16', TYPE.float_: 'f',
                    TYPE.string: 'str'
                    }

        if isinstance(type_, symbols.TYPEREF):
            type_ = type_.final
            assert isinstance(type_, symbols.BASICTYPE)

        if isinstance(type_, symbols.BASICTYPE):
            return _TSUFFIX[type_.type_]

        return _TSUFFIX[type_]

    def ic_aaddr(self, t1, t2):
        return self.emit('aaddr', t1, t2)

    def ic_abs(self, type_, t1, t2):
        return self.emit('abs' + self.TSUFFIX(type_), t1, t2)

    def ic_add(self, type_, t1, t2, t3):
        return self.emit('add' + self.TSUFFIX(type_), t1, t2, t3)

    def ic_aload(self, type_, t1, mangle: str):
        return self.emit('aload' + self.TSUFFIX(type_), t1, mangle)

    def ic_and(self, type_):
        return self.emit('and' + self.TSUFFIX(type_))

    def ic_astore(self, type_, addr: str, t):
        return self.emit('astore' + self.TSUFFIX(type_), addr, t)

    def ic_band(self, type_):
        return self.emit('band' + self.TSUFFIX(type_))

    def ic_bnot(self, type_, t1, t2):
        return self.emit('bnot' + self.TSUFFIX(type_), t1, t2)

    def ic_bor(self, type_):
        return self.emit('bor' + self.TSUFFIX(type_))

    def ic_bxor(self, type_):
        return self.emit('bxor' + self.TSUFFIX(type_))

    def ic_call(self, label: str, num: int):
        return self.emit('call', label, num)

    def ic_cast(self, t1, type1, type2, t2):
        self.emit('cast', t1, self.TSUFFIX(type1), self.TSUFFIX(type2), t2)

    def ic_data(self, type_, data: list):
        return self.emit('data', self.TSUFFIX(type_), data)

    def ic_deflabel(self, label: str, t):
        return self.emit('deflabel', label, t)

    def ic_div(self, type_):
        return self.emit('div' + self.TSUFFIX(type_))

    def ic_end(self, t):
        return self.emit('end', t)

    def ic_enter(self, arg):
        return self.emit('enter', arg)

    def ic_eq(self, type_, t, t1, t2):
        return self.emit('eq' + self.TSUFFIX(type_), t, t1, t2)

    def ic_exchg(self):
        return self.emit('exchg')

    def ic_fparam(self, type_, t):
        return self.emit('fparam' + self.TSUFFIX(type_), t)

    def ic_fpload(self, type_, t, offset):
        return self.emit('fpload' + self.TSUFFIX(type_), t, offset)

    def ic_ge(self, type_, t, t1, t2):
        return self.emit('ge' + self.TSUFFIX(type_), t, t1, t2)

    def ic_gt(self, type_, t, t1, t2):
        return self.emit('gt' + self.TSUFFIX(type_), t, t1, t2)

    def ic_in(self, t):
        return self.emit('in', t)

    def ic_inline(self, asm_code: str, t):
        return self.emit('inline', asm_code, t)

    def ic_jgezero(self, type_, t, label: str):
        return self.emit('jgezero' + self.TSUFFIX(type_), t, label)

    def ic_jnzero(self, type_, t, label: str):
        return self.emit('jnzero' + self.TSUFFIX(type_), t, label)

    def ic_jump(self, label: str):
        return self.emit('jump', label)

    def ic_jzero(self, type_, t, label: str):
        return self.emit('jzero' + self.TSUFFIX(type_), t, label)

    def ic_label(self, label: str):
        return self.emit('label', label)

    def ic_larrd(self, offset, arg1, size, arg2, bound_ptrs):
        return self.emit('larrd', offset, arg1, size, arg2, bound_ptrs)

    def ic_le(self, type_, t, t1, t2):
        return self.emit('le' + self.TSUFFIX(type_), t, t1, t2)

    def ic_leave(self, convention: str):
        return self.emit('leave', convention)

    def ic_lenstr(self, t1, t2):
        return self.emit('lenstr', t1, t2)

    def ic_load(self, type_, t1, t2):
        return self.emit('load' + self.TSUFFIX(type_), t1, t2)

    def ic_lt(self, type_, t, t1, t2):
        return self.emit('lt' + self.TSUFFIX(type_), t, t1, t2)

    def ic_lvard(self, offset, default_value: list):
        return self.emit('lvard', offset, default_value)

    def ic_lvarx(self, type_, offset, default_value: list):
        self.emit('lvarx', offset, self.TSUFFIX(type_), default_value)

    def ic_memcopy(self, t1, t2, t3):
        return self.emit('memcopy', t1, t2, t3)

    def ic_mod(self, type_):
        return self.emit('mod' + self.TSUFFIX(type_))

    def ic_mul(self, type_):
        return self.emit('mul' + self.TSUFFIX(type_))

    def ic_ne(self, type_, t, t1, t2):
        return self.emit('ne' + self.TSUFFIX(type_), t, t1, t2)

    def ic_neg(self, type_, t1, t2):
        return self.emit('neg' + self.TSUFFIX(type_), t1, t2)

    def ic_nop(self):
        return self.emit('nop')

    def ic_not(self, type_, t1, t2):
        return self.emit('not' + self.TSUFFIX(type_), t1, t2)

    def ic_or(self, type_):
        return self.emit('or' + self.TSUFFIX(type_))

    def ic_org(self, type_):
        return self.emit('org' + self.TSUFFIX(type_))

    def ic_out(self, t1, t2):
        return self.emit('out', t1, t2)

    def ic_paaddr(self, t1, t2):
        return self.emit('paaddr', t1, t2)

    def ic_paddr(self, t1, t2):
        return self.emit('paddr', t1, t2)

    def ic_paload(self, type_, t, offset: int):
        return self.emit('paload' + self.TSUFFIX(type_), t, offset)

    def ic_param(self, type_, t):
        return self.emit('param' + self.TSUFFIX(type_), t)

    def ic_pastore(self, type_, offset, t):
        return self.emit('pastore' + self.TSUFFIX(type_), offset, t)

    def ic_pload(self, type_, t1, offset):
        return self.emit('pload' + self.TSUFFIX(type_), t1, offset)

    def ic_pow(self, type_):
        return self.emit('pow' + self.TSUFFIX(type_))

    def ic_pstore(self, type_, offset, t):
        return self.emit('pstore' + self.TSUFFIX(type_), offset, t)

    def ic_ret(self, type_, t, addr):
        return self.emit('ret' + self.TSUFFIX(type_), t, addr)

    def ic_return(self, addr):
        return self.emit('ret', addr)

    def ic_shl(self, type_):
        return self.emit('shl' + self.TSUFFIX(type_))

    def ic_shr(self, type_):
        return self.emit('shr' + self.TSUFFIX(type_))

    def ic_store(self, type_, t1, t2):
        return self.emit('store' + self.TSUFFIX(type_), t1, t2)

    def ic_sub(self, type_):
        return self.emit('sub' + self.TSUFFIX(type_))

    def ic_var(self, name: str, size_):
        return self.emit('var', name, size_)

    def ic_vard(self, name: str, data: list):
        return self.emit('vard', name, data)

    def ic_varx(self, name: str, type_, default_value: list):
        return self.emit('varx', name, self.TSUFFIX(type_), default_value)

    def ic_xor(self, type_):
        return self.emit('xor' + self.TSUFFIX(type_))
