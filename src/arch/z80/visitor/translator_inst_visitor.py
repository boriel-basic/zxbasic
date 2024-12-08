from src.api.constants import TYPE
from src.api.debug import __DEBUG__
from src.arch.interface.quad import Quad
from src.arch.z80.backend import Backend
from src.arch.z80.backend.common import BOOL_t, F16_t, F_t, I8_t, I16_t, I32_t, U8_t, U16_t, U32_t, STR_t
from src.ast import NodeVisitor
from src.symbols import sym as symbols


class TranslatorInstVisitor(NodeVisitor):
    def __init__(self, backend: Backend):
        self.backend = backend

    def emit(self, *args: str) -> None:
        """Convert the given args to a Quad (3 address code) instruction"""
        quad = Quad(*args)
        __DEBUG__(f"EMIT {quad!s}")
        self.backend.MEMORY.append(quad)

    @staticmethod
    def TSUFFIX(type_: TYPE | symbols.TYPEREF | symbols.BASICTYPE) -> str:
        assert isinstance(type_, symbols.TYPE) or TYPE.is_valid(type_)

        _TSUFFIX = {
            TYPE.byte: I8_t,
            TYPE.ubyte: U8_t,
            TYPE.integer: I16_t,
            TYPE.uinteger: U16_t,
            TYPE.long: I32_t,
            TYPE.ulong: U32_t,
            TYPE.fixed: F16_t,
            TYPE.float: F_t,
            TYPE.string: STR_t,
            TYPE.boolean: BOOL_t,
        }

        if isinstance(type_, symbols.TYPEREF):
            type_ = type_.final
            assert isinstance(type_, symbols.BASICTYPE)

        if isinstance(type_, symbols.BASICTYPE):
            return _TSUFFIX[type_.type_]

        return _TSUFFIX[type_]

    @classmethod
    def _no_bool(cls, type_: TYPE | symbols.TYPEREF | symbols.BASICTYPE) -> str:
        """Returns the corresponding type suffix except for bool which maps to U8_t"""
        return cls.TSUFFIX(type_) if cls.TSUFFIX(type_) != BOOL_t else U8_t

    def ic_aaddr(self, t1, t2) -> None:
        self.emit("aaddr", t1, t2)

    def ic_abs(self, type_: TYPE | symbols.BASICTYPE, t1, t2) -> None:
        self.emit("abs" + self.TSUFFIX(type_), t1, t2)

    def ic_add(self, type_: TYPE | symbols.BASICTYPE, t1, t2, t3) -> None:
        self.emit("add" + self.TSUFFIX(type_), t1, t2, t3)

    def ic_aload(self, type_: TYPE | symbols.BASICTYPE, t1, mangle: str) -> None:
        self.emit("aload" + self.TSUFFIX(type_), t1, mangle)

    def ic_and(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit(f"and{self._no_bool(type_)}", t, t1, t2)

    def ic_astore(self, type_: TYPE | symbols.BASICTYPE, addr: str, t) -> None:
        self.emit("astore" + self.TSUFFIX(type_), addr, t)

    def ic_band(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("band" + self.TSUFFIX(type_), t, t1, t2)

    def ic_bnot(self, type_: TYPE | symbols.BASICTYPE, t1, t2) -> None:
        self.emit("bnot" + self.TSUFFIX(type_), t1, t2)

    def ic_bor(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("bor" + self.TSUFFIX(type_), t, t1, t2)

    def ic_bxor(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("bxor" + self.TSUFFIX(type_), t, t1, t2)

    def ic_call(self, label: str, num: int) -> None:
        self.emit("call", label, num)

    def ic_cast(self, t1, type1, type2, t2) -> None:
        self.emit("cast", t1, self.TSUFFIX(type1), self.TSUFFIX(type2), t2)

    def ic_data(self, type_: TYPE | symbols.BASICTYPE, data: list) -> None:
        self.emit("data", self.TSUFFIX(type_), data)

    def ic_deflabel(self, label: str, t) -> None:
        self.emit("deflabel", label, t)

    def ic_div(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("div" + self.TSUFFIX(type_), t, t1, t2)

    def ic_end(self, t) -> None:
        self.emit("end", t)

    def ic_enter(self, arg) -> None:
        self.emit("enter", arg)

    def ic_eq(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("eq" + self.TSUFFIX(type_), t, t1, t2)

    def ic_exchg(self) -> None:
        self.emit("exchg")

    def ic_fparam(self, type_: TYPE | symbols.BASICTYPE, t) -> None:
        self.emit("fparam" + self.TSUFFIX(type_), t)

    def ic_fpload(self, type_: TYPE | symbols.BASICTYPE, t, offset) -> None:
        self.emit("fpload" + self.TSUFFIX(type_), t, offset)

    def ic_ge(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("ge" + self.TSUFFIX(type_), t, t1, t2)

    def ic_gt(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("gt" + self.TSUFFIX(type_), t, t1, t2)

    def ic_in(self, t) -> None:
        self.emit("in", t)

    def ic_inline(self, asm_code: str) -> None:
        self.emit("inline", asm_code)

    def ic_jgezero(self, type_: TYPE | symbols.BASICTYPE, t, label: str) -> None:
        self.emit(f"jgezero{self._no_bool(type_)}", t, label)

    def ic_jnzero(self, type_: TYPE | symbols.BASICTYPE, t, label: str) -> None:
        self.emit(f"jnzero{self._no_bool(type_)}", t, label)

    def ic_jump(self, label: str) -> None:
        self.emit("jump", label)

    def ic_jzero(self, type_: TYPE | symbols.BASICTYPE, t, label: str) -> None:
        self.emit(f"jzero{self._no_bool(type_)}", t, label)

    def ic_label(self, label: str) -> None:
        self.emit("label", label)

    def ic_larrd(self, offset, arg1, size, arg2, bound_ptrs) -> None:
        self.emit("larrd", offset, arg1, size, arg2, bound_ptrs)

    def ic_le(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("le" + self.TSUFFIX(type_), t, t1, t2)

    def ic_leave(self, convention: str) -> None:
        self.emit("leave", convention)

    def ic_lenstr(self, t1, t2) -> None:
        self.emit("lenstr", t1, t2)

    def ic_load(self, type_: TYPE | symbols.BASICTYPE, t1, t2) -> None:
        self.emit("load" + self.TSUFFIX(type_), t1, t2)

    def ic_lt(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("lt" + self.TSUFFIX(type_), t, t1, t2)

    def ic_lvard(self, offset, default_value: list) -> None:
        self.emit("lvard", offset, default_value)

    def ic_lvarx(self, type_: TYPE | symbols.BASICTYPE, offset, default_value: list) -> None:
        self.emit("lvarx", offset, self.TSUFFIX(type_), default_value)

    def ic_memcopy(self, t1, t2, t3) -> None:
        self.emit("memcopy", t1, t2, t3)

    def ic_mod(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("mod" + self.TSUFFIX(type_), t, t1, t2)

    def ic_mul(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("mul" + self.TSUFFIX(type_), t, t1, t2)

    def ic_ne(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("ne" + self.TSUFFIX(type_), t, t1, t2)

    def ic_neg(self, type_: TYPE | symbols.BASICTYPE, t1, t2) -> None:
        self.emit("neg" + self.TSUFFIX(type_), t1, t2)

    def ic_nop(self) -> None:
        self.emit("nop")

    def ic_not(self, type_: TYPE | symbols.BASICTYPE, t1, t2) -> None:
        self.emit(f"not{self._no_bool(type_)}", t1, t2)

    def ic_or(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit(f"or{self._no_bool(type_)}", t, t1, t2)

    def ic_org(self, type_: TYPE | symbols.BASICTYPE) -> None:
        self.emit("org" + self.TSUFFIX(type_))

    def ic_out(self, t1, t2) -> None:
        self.emit("out", t1, t2)

    def ic_paaddr(self, t1, t2) -> None:
        self.emit("paaddr", t1, t2)

    def ic_paddr(self, t1, t2) -> None:
        self.emit("paddr", t1, t2)

    def ic_paload(self, type_: TYPE | symbols.BASICTYPE, t, offset: int) -> None:
        self.emit("paload" + self.TSUFFIX(type_), t, offset)

    def ic_param(self, type_: TYPE | symbols.BASICTYPE, t) -> None:
        self.emit("param" + self.TSUFFIX(type_), t)

    def ic_pastore(self, type_: TYPE | symbols.BASICTYPE, offset, t) -> None:
        self.emit("pastore" + self.TSUFFIX(type_), offset, t)

    def ic_pload(self, type_: TYPE | symbols.BASICTYPE, t1, offset) -> None:
        self.emit("pload" + self.TSUFFIX(type_), t1, offset)

    def ic_pow(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("pow" + self.TSUFFIX(type_), t, t1, t2)

    def ic_pstore(self, type_: TYPE | symbols.BASICTYPE, offset, t) -> None:
        self.emit("pstore" + self.TSUFFIX(type_), offset, t)

    def ic_ret(self, type_: TYPE | symbols.BASICTYPE, t, addr) -> None:
        self.emit("ret" + self.TSUFFIX(type_), t, addr)

    def ic_return(self, addr) -> None:
        self.emit("ret", addr)

    def ic_shl(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("shl" + self.TSUFFIX(type_), t, t1, t2)

    def ic_shr(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("shr" + self.TSUFFIX(type_), t, t1, t2)

    def ic_store(self, type_: TYPE | symbols.BASICTYPE, t1, t2) -> None:
        self.emit("store" + self.TSUFFIX(type_), t1, t2)

    def ic_sub(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("sub" + self.TSUFFIX(type_), t, t1, t2)

    def ic_var(self, name: str, size_) -> None:
        self.emit("var", name, size_)

    def ic_vard(self, name: str, data: list) -> None:
        self.emit("vard", name, data)

    def ic_varx(self, name: str, type_: TYPE | symbols.BASICTYPE, default_value: list) -> None:
        self.emit("varx", name, self.TSUFFIX(type_), default_value)

    def ic_xor(self, type_: TYPE | symbols.BASICTYPE, t, t1, t2) -> None:
        self.emit("xor" + self.TSUFFIX(type_), t, t1, t2)
