from __future__ import annotations

import re
from collections import defaultdict

from src.api.config import OPTIONS
from src.api.options import Action
from src.api.tmp_labels import TMP_LABELS
from src.arch.interface.backend import BackendInterface
from src.arch.z80.optimizer.asm import Asm
from src.arch.z80.peephole import engine

from . import common

# 8 bit bitwise operations
# 8 bit shift operations
# 8 bit boolean functions
# 8 bit comparison functions
# 8 bit parameters and function call instrs
# 8 bit arithmetic functions
from ._8bit import (
    _abs8,
    _add8,
    _and8,
    _band8,
    _bnot8,
    _bor8,
    _bxor8,
    _divi8,
    _divu8,
    _eq8,
    _fparam8,
    _gei8,
    _geu8,
    _gti8,
    _gtu8,
    _jgezeroi8,
    _jgezerou8,
    _jnzero8,
    _jzero8,
    _lei8,
    _leu8,
    _load8,
    _lti8,
    _ltu8,
    _modi8,
    _modu8,
    _mul8,
    _ne8,
    _neg8,
    _not8,
    _or8,
    _param8,
    _ret8,
    _shl8,
    _shri8,
    _shru8,
    _store8,
    _sub8,
    _xor8,
)

# 16 bit bitwise operations
# 16 bit shift operations
# 16 bit boolean functions
# 16 bit comparison functions
# 16bit parameters and function call instrs
# 16 bit arithmetic functions
from ._16bit import (
    _abs16,
    _add16,
    _and16,
    _band16,
    _bnot16,
    _bor16,
    _bxor16,
    _divi16,
    _divu16,
    _eq16,
    _fparam16,
    _gei16,
    _geu16,
    _gti16,
    _gtu16,
    _jgezeroi16,
    _jgezerou16,
    _jnzero16,
    _jzero16,
    _lei16,
    _leu16,
    _load16,
    _lti16,
    _ltu16,
    _modi16,
    _modu16,
    _mul16,
    _ne16,
    _neg16,
    _not16,
    _or16,
    _param16,
    _ret16,
    _shl16,
    _shri16,
    _shru16,
    _store16,
    _sub16,
    _xor16,
)

# 32 bit bitwise operations
# 32 bit shift operations
# 32 bit boolean functions
# 32 bit comparison functions
# 32 bit parameters and function call instrs
# 32 bit arithmetic functions
from ._32bit import (
    _abs32,
    _add32,
    _and32,
    _band32,
    _bnot32,
    _bor32,
    _bxor32,
    _divi32,
    _divu32,
    _eq32,
    _fparam32,
    _gei32,
    _geu32,
    _gti32,
    _gtu32,
    _jgezeroi32,
    _jgezerou32,
    _jnzero32,
    _jzero32,
    _lei32,
    _leu32,
    _load32,
    _lti32,
    _ltu32,
    _modi32,
    _modu32,
    _mul32,
    _ne32,
    _neg32,
    _not32,
    _or32,
    _param32,
    _ret32,
    _shl32,
    _shri32,
    _shru32,
    _store32,
    _sub32,
    _xor32,
)

# Array store and load instructions
from ._array import (
    _aaddr,
    _aload8,
    _aload16,
    _aload32,
    _aloadf,
    _aloadstr,
    _astore8,
    _astore16,
    _astore32,
    _astoref,
    _astoref16,
    _astorestr,
)

# Fixed Point boolean functions
# Fixed Point comparison functions
# f16 parameters and function call instrs
# Fixed Point arithmetic functions
from ._f16 import (
    _absf16,
    _addf16,
    _andf16,
    _divf16,
    _eqf16,
    _fparamf16,
    _gef16,
    _gtf16,
    _jgezerof16,
    _jnzerof16,
    _jzerof16,
    _lef16,
    _loadf16,
    _ltf16,
    _modf16,
    _mulf16,
    _nef16,
    _negf16,
    _notf16,
    _orf16,
    _paramf16,
    _retf16,
    _storef16,
    _subf16,
    _xorf16,
)

# Floating Point boolean functions
# Floating Point comparison functions
# Floating Point parameters and function call instrs
# Floating Point arithmetic functions
from ._float import (
    _absf,
    _addf,
    _andf,
    _divf,
    _eqf,
    _fparamf,
    _gef,
    _gtf,
    _jgezerof,
    _jnzerof,
    _jzerof,
    _lef,
    _loadf,
    _ltf,
    _modf,
    _mulf,
    _nef,
    _negf,
    _notf,
    _orf,
    _paramf,
    _powf,
    _retf,
    _storef,
    _subf,
    _xorf,
)

# Array store and load instructions
from ._parray import (
    _paaddr,
    _paload8,
    _paload16,
    _paload32,
    _paloadf,
    _paloadstr,
    _pastore8,
    _pastore16,
    _pastore32,
    _pastoref,
    _pastoref16,
    _pastorestr,
)

# Param load and store instructions
from ._pload import (
    _fploadstr,
    _paddr,
    _pload8,
    _pload16,
    _pload32,
    _ploadf,
    _ploadstr,
    _pstore8,
    _pstore16,
    _pstore32,
    _pstoref,
    _pstoref16,
    _pstorestr,
)

# String comparison functions
# String arithmetic functions
from ._str import (
    _addstr,
    _eqstr,
    _fparamstr,
    _gestr,
    _gtstr,
    _jnzerostr,
    _jzerostr,
    _lenstr,
    _lestr,
    _loadstr,
    _ltstr,
    _nestr,
    _paramstr,
    _retstr,
    _storestr,
)
from .common import runtime_call
from .generic import (
    _call,
    _cast,
    _data,
    _deflabel,
    _end,
    _enter,
    _exchg,
    _in,
    _inline,
    _jump,
    _label,
    _larrd,
    _leave,
    _lvard,
    _lvarx,
    _memcopy,
    _nop,
    _org,
    _out,
    _ret,
    _var,
    _vard,
    _varx,
)
from .icinfo import ICInfo
from .icinstruction import ICInstruction
from .quad import Quad
from .runtime import NAMESPACE
from .runtime import Labels as RuntimeLabel

__all__ = ("Backend",)


class Backend(BackendInterface):
    """Implements a backend for the Z80 architecture."""

    #  Table describing operations
    # 'OPERATOR' -> (Number of arguments, emitting func)
    _QUAD_TABLE: dict[str, ICInfo] = {}
    MEMORY: list[Quad] = []  # Must be initialized by with init()

    def __init__(self):
        self.init()

    def _set_quad_table(self):
        """Lowlevel (to ASM) instructions implementation"""
        self._QUAD_TABLE = {
            ICInstruction.ADDU8: ICInfo(3, _add8),
            ICInstruction.ADDI8: ICInfo(3, _add8),
            ICInstruction.ADDI16: ICInfo(3, _add16),
            ICInstruction.ADDU16: ICInfo(3, _add16),
            ICInstruction.ADDI32: ICInfo(3, _add32),
            ICInstruction.ADDU32: ICInfo(3, _add32),
            ICInstruction.ADDF16: ICInfo(3, _addf16),
            ICInstruction.ADDF: ICInfo(3, _addf),
            ICInstruction.ADDSTR: ICInfo(3, _addstr),
            ICInstruction.DATA: ICInfo(2, _data),
            ICInstruction.SUBI8: ICInfo(3, _sub8),
            ICInstruction.SUBU8: ICInfo(3, _sub8),
            ICInstruction.SUBI16: ICInfo(3, _sub16),
            ICInstruction.SUBU16: ICInfo(3, _sub16),
            ICInstruction.SUBI32: ICInfo(3, _sub32),
            ICInstruction.SUBU32: ICInfo(3, _sub32),
            ICInstruction.SUBF16: ICInfo(3, _subf16),
            ICInstruction.SUBF: ICInfo(3, _subf),
            ICInstruction.MULI8: ICInfo(3, _mul8),
            ICInstruction.MULU8: ICInfo(3, _mul8),
            ICInstruction.MULI16: ICInfo(3, _mul16),
            ICInstruction.MULU16: ICInfo(3, _mul16),
            ICInstruction.MULI32: ICInfo(3, _mul32),
            ICInstruction.MULU32: ICInfo(3, _mul32),
            ICInstruction.MULF16: ICInfo(3, _mulf16),
            ICInstruction.MULF: ICInfo(3, _mulf),
            ICInstruction.DIVU8: ICInfo(3, _divu8),
            ICInstruction.DIVI8: ICInfo(3, _divi8),
            ICInstruction.DIVU16: ICInfo(3, _divu16),
            ICInstruction.DIVI16: ICInfo(3, _divi16),
            ICInstruction.DIVU32: ICInfo(3, _divu32),
            ICInstruction.DIVI32: ICInfo(3, _divi32),
            ICInstruction.DIVF16: ICInfo(3, _divf16),
            ICInstruction.DIVF: ICInfo(3, _divf),
            ICInstruction.POWF: ICInfo(3, _powf),
            ICInstruction.MODU8: ICInfo(3, _modu8),
            ICInstruction.MODI8: ICInfo(3, _modi8),
            ICInstruction.MODU16: ICInfo(3, _modu16),
            ICInstruction.MODI16: ICInfo(3, _modi16),
            ICInstruction.MODU32: ICInfo(3, _modu32),
            ICInstruction.MODI32: ICInfo(3, _modi32),
            ICInstruction.MODF16: ICInfo(3, _modf16),
            ICInstruction.MODF: ICInfo(3, _modf),
            ICInstruction.SHRU8: ICInfo(3, _shru8),
            ICInstruction.SHRI8: ICInfo(3, _shri8),
            ICInstruction.SHLU8: ICInfo(3, _shl8),
            ICInstruction.SHLI8: ICInfo(3, _shl8),
            ICInstruction.SHRU16: ICInfo(3, _shru16),
            ICInstruction.SHRI16: ICInfo(3, _shri16),
            ICInstruction.SHLU16: ICInfo(3, _shl16),
            ICInstruction.SHLI16: ICInfo(3, _shl16),
            ICInstruction.SHRU32: ICInfo(3, _shru32),
            ICInstruction.SHRI32: ICInfo(3, _shri32),
            ICInstruction.SHLU32: ICInfo(3, _shl32),
            ICInstruction.SHLI32: ICInfo(3, _shl32),
            ICInstruction.LTU8: ICInfo(3, _ltu8),
            ICInstruction.LTI8: ICInfo(3, _lti8),
            ICInstruction.LTU16: ICInfo(3, _ltu16),
            ICInstruction.LTI16: ICInfo(3, _lti16),
            ICInstruction.LTU32: ICInfo(3, _ltu32),
            ICInstruction.LTI32: ICInfo(3, _lti32),
            ICInstruction.LTF16: ICInfo(3, _ltf16),
            ICInstruction.LTF: ICInfo(3, _ltf),
            ICInstruction.LTSTR: ICInfo(3, _ltstr),
            ICInstruction.GTU8: ICInfo(3, _gtu8),
            ICInstruction.GTI8: ICInfo(3, _gti8),
            ICInstruction.GTU16: ICInfo(3, _gtu16),
            ICInstruction.GTI16: ICInfo(3, _gti16),
            ICInstruction.GTU32: ICInfo(3, _gtu32),
            ICInstruction.GTI32: ICInfo(3, _gti32),
            ICInstruction.GTF16: ICInfo(3, _gtf16),
            ICInstruction.GTF: ICInfo(3, _gtf),
            ICInstruction.GTSTR: ICInfo(3, _gtstr),
            ICInstruction.LEU8: ICInfo(3, _leu8),
            ICInstruction.LEI8: ICInfo(3, _lei8),
            ICInstruction.LEU16: ICInfo(3, _leu16),
            ICInstruction.LEI16: ICInfo(3, _lei16),
            ICInstruction.LEU32: ICInfo(3, _leu32),
            ICInstruction.LEI32: ICInfo(3, _lei32),
            ICInstruction.LEF16: ICInfo(3, _lef16),
            ICInstruction.LEF: ICInfo(3, _lef),
            ICInstruction.LESTR: ICInfo(3, _lestr),
            ICInstruction.GEU8: ICInfo(3, _geu8),
            ICInstruction.GEI8: ICInfo(3, _gei8),
            ICInstruction.GEU16: ICInfo(3, _geu16),
            ICInstruction.GEI16: ICInfo(3, _gei16),
            ICInstruction.GEU32: ICInfo(3, _geu32),
            ICInstruction.GEI32: ICInfo(3, _gei32),
            ICInstruction.GEF16: ICInfo(3, _gef16),
            ICInstruction.GEF: ICInfo(3, _gef),
            ICInstruction.GESTR: ICInfo(3, _gestr),
            ICInstruction.EQU8: ICInfo(3, _eq8),
            ICInstruction.EQI8: ICInfo(3, _eq8),
            ICInstruction.EQU16: ICInfo(3, _eq16),
            ICInstruction.EQI16: ICInfo(3, _eq16),
            ICInstruction.EQU32: ICInfo(3, _eq32),
            ICInstruction.EQI32: ICInfo(3, _eq32),
            ICInstruction.EQF16: ICInfo(3, _eqf16),
            ICInstruction.EQF: ICInfo(3, _eqf),
            ICInstruction.EQSTR: ICInfo(3, _eqstr),
            ICInstruction.NEU8: ICInfo(3, _ne8),
            ICInstruction.NEI8: ICInfo(3, _ne8),
            ICInstruction.NEU16: ICInfo(3, _ne16),
            ICInstruction.NEI16: ICInfo(3, _ne16),
            ICInstruction.NEU32: ICInfo(3, _ne32),
            ICInstruction.NEI32: ICInfo(3, _ne32),
            ICInstruction.NEF16: ICInfo(3, _nef16),
            ICInstruction.NEF: ICInfo(3, _nef),
            ICInstruction.NESTR: ICInfo(3, _nestr),
            ICInstruction.ABSI8: ICInfo(2, _abs8),  # x = -x if x < 0
            ICInstruction.ABSI16: ICInfo(2, _abs16),  # x = -x if x < 0
            ICInstruction.ABSI32: ICInfo(2, _abs32),  # x = -x if x < 0
            ICInstruction.ABSF16: ICInfo(2, _absf16),  # x = -x if x < 0
            ICInstruction.ABSF: ICInfo(2, _absf),  # x = -x if x < 0
            ICInstruction.NEGU8: ICInfo(2, _neg8),  # x = -y
            ICInstruction.NEGI8: ICInfo(2, _neg8),  # x = -y
            ICInstruction.NEGU16: ICInfo(2, _neg16),  # x = -y
            ICInstruction.NEGI16: ICInfo(2, _neg16),  # x = -y
            ICInstruction.NEGU32: ICInfo(2, _neg32),  # x = -y
            ICInstruction.NEGI32: ICInfo(2, _neg32),  # x = -y
            ICInstruction.NEGF16: ICInfo(2, _negf16),  # x = -y
            ICInstruction.NEGF: ICInfo(2, _negf),  # x = -y
            ICInstruction.ANDU8: ICInfo(3, _and8),  # x = A and B
            ICInstruction.ANDI8: ICInfo(3, _and8),  # x = A and B
            ICInstruction.ANDU16: ICInfo(3, _and16),  # x = A and B
            ICInstruction.ANDI16: ICInfo(3, _and16),  # x = A and B
            ICInstruction.ANDU32: ICInfo(3, _and32),  # x = A and B
            ICInstruction.ANDI32: ICInfo(3, _and32),  # x = A and B
            ICInstruction.ANDF16: ICInfo(3, _andf16),  # x = A and B
            ICInstruction.ANDF: ICInfo(3, _andf),  # x = A and B
            ICInstruction.ORU8: ICInfo(3, _or8),  # x = A or B
            ICInstruction.ORI8: ICInfo(3, _or8),  # x = A or B
            ICInstruction.ORU16: ICInfo(3, _or16),  # x = A or B
            ICInstruction.ORI16: ICInfo(3, _or16),  # x = A or B
            ICInstruction.ORU32: ICInfo(3, _or32),  # x = A or B
            ICInstruction.ORI32: ICInfo(3, _or32),  # x = A or B
            ICInstruction.ORF16: ICInfo(3, _orf16),  # x = A or B
            ICInstruction.ORF: ICInfo(3, _orf),  # x = A or B
            ICInstruction.XORU8: ICInfo(3, _xor8),  # x = A xor B
            ICInstruction.XORI8: ICInfo(3, _xor8),  # x = A xor B
            ICInstruction.XORU16: ICInfo(3, _xor16),  # x = A xor B
            ICInstruction.XORI16: ICInfo(3, _xor16),  # x = A xor B
            ICInstruction.XORU32: ICInfo(3, _xor32),  # x = A xor B
            ICInstruction.XORI32: ICInfo(3, _xor32),  # x = A xor B
            ICInstruction.XORF16: ICInfo(3, _xorf16),  # x = A xor B
            ICInstruction.XORF: ICInfo(3, _xorf),  # x = A xor B
            ICInstruction.NOTU8: ICInfo(2, _not8),  # x = not B
            ICInstruction.NOTI8: ICInfo(2, _not8),  # x = not B
            ICInstruction.NOTU16: ICInfo(2, _not16),  # x = not B
            ICInstruction.NOTI16: ICInfo(2, _not16),  # x = not B
            ICInstruction.NOTU32: ICInfo(2, _not32),  # x = not B
            ICInstruction.NOTI32: ICInfo(2, _not32),  # x = not B
            ICInstruction.NOTF16: ICInfo(2, _notf16),  # x = not B
            ICInstruction.NOTF: ICInfo(2, _notf),  # x = not B
            ICInstruction.JUMP: ICInfo(1, _jump),  # jmp LABEL
            ICInstruction.LENSTR: ICInfo(2, _lenstr),  # Gets strlen
            ICInstruction.JZEROI8: ICInfo(2, _jzero8),  # if X == 0 jmp LABEL
            ICInstruction.JZEROU8: ICInfo(2, _jzero8),  # if X == 0 jmp LABEL
            ICInstruction.JZEROI16: ICInfo(2, _jzero16),  # if X == 0 jmp LABEL
            ICInstruction.JZEROU16: ICInfo(2, _jzero16),  # if X == 0 jmp LABEL
            ICInstruction.JZEROI32: ICInfo(2, _jzero32),  # if X == 0 jmp LABEL (32bit, fixed)
            ICInstruction.JZEROU32: ICInfo(2, _jzero32),  # if X == 0 jmp LABEL (32bit, fixed)
            ICInstruction.JZEROF16: ICInfo(2, _jzerof16),  # if X == 0 jmp LABEL (32bit, fixed)
            ICInstruction.JZEROF: ICInfo(2, _jzerof),  # if X == 0 jmp LABEL (float)
            ICInstruction.JZEROSTR: ICInfo(2, _jzerostr),  # if str is NULL or len(str) == 0, jmp LABEL
            ICInstruction.JNZEROI8: ICInfo(2, _jnzero8),  # if X != 0 jmp LABEL
            ICInstruction.JNZEROU8: ICInfo(2, _jnzero8),  # if X != 0 jmp LABEL
            ICInstruction.JNZEROI16: ICInfo(2, _jnzero16),  # if X != 0 jmp LABEL
            ICInstruction.JNZEROU16: ICInfo(2, _jnzero16),  # if X != 0 jmp LABEL
            ICInstruction.JNZEROI32: ICInfo(2, _jnzero32),  # if X != 0 jmp LABEL (32bit, fixed)
            ICInstruction.JNZEROU32: ICInfo(2, _jnzero32),  # if X != 0 jmp LABEL (32bit, fixed)
            ICInstruction.JNZEROF16: ICInfo(2, _jnzerof16),  # if X != 0 jmp LABEL (32bit, fixed)
            ICInstruction.JNZEROF: ICInfo(2, _jnzerof),  # if X != 0 jmp LABEL (float)
            ICInstruction.JNZEROSTR: ICInfo(2, _jnzerostr),  # if str is not NULL and len(str) > 0, jmp LABEL
            ICInstruction.JGEZEROI8: ICInfo(2, _jgezeroi8),  # if X >= 0 jmp LABEL
            ICInstruction.JGEZEROU8: ICInfo(2, _jgezerou8),  # if X >= 0 jmp LABEL (ALWAYS TRUE)
            ICInstruction.JGEZEROI16: ICInfo(2, _jgezeroi16),  # if X >= 0 jmp LABEL
            ICInstruction.JGEZEROU16: ICInfo(2, _jgezerou16),  # if X >= 0 jmp LABEL (ALWAYS TRUE)
            ICInstruction.JGEZEROI32: ICInfo(2, _jgezeroi32),  # if X >= 0 jmp LABEL (32bit, fixed)
            ICInstruction.JGEZEROU32: ICInfo(2, _jgezerou32),  # if X >= 0 jmp LABEL (32bit, fixed) (always true)
            ICInstruction.JGEZEROF16: ICInfo(2, _jgezerof16),  # if X >= 0 jmp LABEL (32bit, fixed)
            ICInstruction.JGEZEROF: ICInfo(2, _jgezerof),  # if X >= 0 jmp LABEL (float)
            ICInstruction.PARAMU8: ICInfo(1, _param8),  # Push 8 bit param onto the stack
            ICInstruction.PARAMI8: ICInfo(1, _param8),  # Push 8 bit param onto the stack
            ICInstruction.PARAMU16: ICInfo(1, _param16),  # Push 16 bit param onto the stack
            ICInstruction.PARAMI16: ICInfo(1, _param16),  # Push 16 bit param onto the stack
            ICInstruction.PARAMU32: ICInfo(1, _param32),  # Push 32 bit param onto the stack
            ICInstruction.PARAMI32: ICInfo(1, _param32),  # Push 32 bit param onto the stack
            ICInstruction.PARAMF16: ICInfo(1, _paramf16),  # Push 32 bit param onto the stack
            ICInstruction.PARAMF: ICInfo(1, _paramf),  # Push float param - 6 BYTES (always even) onto the stack
            ICInstruction.PARAMSTR: ICInfo(1, _paramstr),  # Push float param - 6 BYTES (always even) onto the stack
            ICInstruction.FPARAMU8: ICInfo(1, _fparam8),  # __FASTCALL__ parameter
            ICInstruction.FPARAMI8: ICInfo(1, _fparam8),  # __FASTCALL__ parameter
            ICInstruction.FPARAMU16: ICInfo(1, _fparam16),  # __FASTCALL__ parameter
            ICInstruction.FPARAMI16: ICInfo(1, _fparam16),  # __FASTCALL__ parameter
            ICInstruction.FPARAMU32: ICInfo(1, _fparam32),  # __FASTCALL__ parameter
            ICInstruction.FPARAMI32: ICInfo(1, _fparam32),  # __FASTCALL__ parameter
            ICInstruction.FPARAMF16: ICInfo(1, _fparamf16),  # __FASTCALL__ parameter
            ICInstruction.FPARAMF: ICInfo(1, _fparamf),  # __FASTCALL__ parameter
            ICInstruction.FPARAMSTR: ICInfo(1, _fparamstr),  # __FASTCALL__ parameter
            ICInstruction.CALL: ICInfo(
                2, _call
            ),  # Call Address, NNNN - NNNN = Size (in bytes) of the returned value (0 for procedure)
            ICInstruction.RET: ICInfo(
                1, _ret
            ),  # Returns from a function call (enters the 'leave' sequence'), returning no value
            ICInstruction.RETI8: ICInfo(
                2, _ret8
            ),  # Returns from a function call (enters the 'leave' sequence'), returning 8 bit value
            ICInstruction.RETU8: ICInfo(
                2, _ret8
            ),  # Returns from a function call (enters the 'leave' sequence'), returning 8 bit value
            ICInstruction.RETI16: ICInfo(
                2, _ret16
            ),  # Returns from a func call (enters the 'leave' sequence'), returning 16 bit value
            ICInstruction.RETU16: ICInfo(
                2, _ret16
            ),  # Returns from a func call (enters the 'leave' sequence'), returning 16 bit value
            ICInstruction.RETI32: ICInfo(
                2, _ret32
            ),  # Returns from a func call (enters the 'leave' sequence'), returning 32 bit value
            ICInstruction.RETU32: ICInfo(
                2, _ret32
            ),  # Returns from a func call (enters the 'leave' sequence'), returning 32 bit value
            ICInstruction.RETF16: ICInfo(
                2, _retf16
            ),  # Returns from a func call (enters the 'leave' sequence'), returning fixed point
            ICInstruction.RETF: ICInfo(
                2, _retf
            ),  # Returns from a function call (enters the 'leave' sequence'), returning fixed point
            ICInstruction.RETSTR: ICInfo(
                2, _retstr
            ),  # Returns from a func call (enters the 'leave' sequence'), returning fixed point
            ICInstruction.LEAVE: ICInfo(
                1, _leave
            ),  # LEAVE label, NN -> NN = Size of parameters in bytes (End of function <label>)
            ICInstruction.ENTER: ICInfo(
                1, _enter
            ),  # ENTER proc/func; NN = size of local variables in bytes (Function beginning)
            ICInstruction.ORG: ICInfo(1, _org),  # Defines code location
            ICInstruction.END: ICInfo(1, _end),  # Defines an end sequence
            ICInstruction.LABEL: ICInfo(1, _label),  # Defines a label # Flow control instructions
            ICInstruction.DEFLABEL: ICInfo(2, _deflabel),  # Defines a label with a value
            ICInstruction.OUT: ICInfo(2, _out),  # Defines a OUT instruction OUT x, y
            ICInstruction.IN: ICInfo(1, _in),  # Defines an IN instruction IN x, y
            ICInstruction.INLINE: ICInfo(1, _inline),  # Defines an inline asm instruction
            ICInstruction.CAST: ICInfo(4, _cast),
            # TYPECAST: X = cast(from Type1, to Type2, Y) Ej. Converts Y 16bit to X 8bit: (cast, x, u16, u8, y)
            ICInstruction.STOREI8: ICInfo(
                2, _store8
            ),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.STOREU8: ICInfo(
                2, _store8
            ),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.STOREI16: ICInfo(
                2, _store16
            ),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.STOREU16: ICInfo(
                2, _store16
            ),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.STOREI32: ICInfo(
                2, _store32
            ),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.STOREU32: ICInfo(
                2, _store32
            ),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.STOREF16: ICInfo(
                2, _storef16
            ),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.STOREF: ICInfo(2, _storef),
            ICInstruction.STORESTR: ICInfo(
                2, _storestr
            ),  # STORE STR1 <-- STR2 : Store string: Reallocs STR1 and copies STR2 into STR1
            ICInstruction.ASTOREI8: ICInfo(
                2, _astore8
            ),  # ARRAY STORE nnnn, X -> Stores X at position N (Type of X determines X size)
            ICInstruction.ASTOREU8: ICInfo(
                2, _astore8
            ),  # ARRAY STORE nnnn, X -> Stores X at position N (Type of X determines X size)
            ICInstruction.ASTOREI16: ICInfo(
                2, _astore16
            ),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
            ICInstruction.ASTOREU16: ICInfo(
                2, _astore16
            ),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
            ICInstruction.ASTOREI32: ICInfo(
                2, _astore32
            ),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
            ICInstruction.ASTOREU32: ICInfo(
                2, _astore32
            ),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
            ICInstruction.ASTOREF16: ICInfo(
                2, _astoref16
            ),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
            ICInstruction.ASTOREF: ICInfo(2, _astoref),
            ICInstruction.ASTORESTR: ICInfo(2, _astorestr),
            # ARRAY STORE STR1 <-- STR2 : Store string: Reallocs STR1 and then copies STR2 into STR1
            ICInstruction.LOADI8: ICInfo(
                2, _load8
            ),  # LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
            ICInstruction.LOADU8: ICInfo(
                2, _load8
            ),  # LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
            ICInstruction.LOADI16: ICInfo(2, _load16),  # LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.LOADU16: ICInfo(2, _load16),  # LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.LOADI32: ICInfo(2, _load32),  # LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.LOADU32: ICInfo(2, _load32),  # LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.LOADF16: ICInfo(2, _loadf16),  # LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.LOADF: ICInfo(2, _loadf),  # LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.LOADSTR: ICInfo(2, _loadstr),  # LOAD X, nnnn -> Load string value at nnnn into X
            ICInstruction.ALOADI8: ICInfo(
                2, _aload8
            ),  # ARRAY LOAD X, nnnn -> Load mem content at nnnn into X (X must be a temporal)
            ICInstruction.ALOADU8: ICInfo(
                2, _aload8
            ),  # ARRAY LOAD X, nnnn -> Load mem content at nnnn into X (X must be a temporal)
            ICInstruction.ALOADI16: ICInfo(2, _aload16),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.ALOADU16: ICInfo(2, _aload16),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.ALOADI32: ICInfo(2, _aload32),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.ALOADU32: ICInfo(2, _aload32),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.ALOADF16: ICInfo(2, _aload32),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.ALOADF: ICInfo(2, _aloadf),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
            ICInstruction.ALOADSTR: ICInfo(2, _aloadstr),  # ARRAY LOAD X, nnnn -> Load string value at nnnn into X
            ICInstruction.PSTOREI8: ICInfo(
                2, _pstore8
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PSTOREU8: ICInfo(
                2, _pstore8
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PSTOREI16: ICInfo(
                2, _pstore16
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PSTOREU16: ICInfo(
                2, _pstore16
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PSTOREI32: ICInfo(
                2, _pstore32
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PSTOREU32: ICInfo(
                2, _pstore32
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PSTOREF16: ICInfo(
                2, _pstoref16
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PSTOREF: ICInfo(
                2, _pstoref
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PSTORESTR: ICInfo(
                2, _pstorestr
            ),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTOREI8: ICInfo(2, _pastore8),
            # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTOREU8: ICInfo(2, _pastore8),
            # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTOREI16: ICInfo(2, _pastore16),
            # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTOREU16: ICInfo(2, _pastore16),
            # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTOREI32: ICInfo(2, _pastore32),
            # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTOREU32: ICInfo(2, _pastore32),
            # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTOREF16: ICInfo(2, _pastoref16),
            # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTOREF: ICInfo(
                2,
                _pastoref,
            ),  # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PASTORESTR: ICInfo(2, _pastorestr),
            # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
            ICInstruction.PLOADI8: ICInfo(2, _pload8),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PLOADU8: ICInfo(2, _pload8),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PLOADI16: ICInfo(2, _pload16),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PLOADU16: ICInfo(2, _pload16),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PLOADI32: ICInfo(2, _pload32),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PLOADU32: ICInfo(2, _pload32),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PLOADF16: ICInfo(2, _pload32),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PLOADF: ICInfo(2, _ploadf),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PLOADSTR: ICInfo(2, _ploadstr),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PADDR: ICInfo(2, _paddr),  # LOADS IX + nnnn into the stack
            ICInstruction.AADDR: ICInfo(2, _aaddr),  # LOADS ADDRESS of global ARRAY element into the stack
            ICInstruction.PAADDR: ICInfo(2, _paaddr),  # LOADS ADDRESS of local ARRAY element into the stack
            ICInstruction.PALOADI8: ICInfo(
                2, _paload8
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PALOADU8: ICInfo(
                2, _paload8
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PALOADI16: ICInfo(
                2, _paload16
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PALOADU16: ICInfo(
                2, _paload16
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PALOADI32: ICInfo(
                2, _paload32
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PALOADU32: ICInfo(
                2, _paload32
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PALOADF16: ICInfo(
                2, _paload32
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PALOADF: ICInfo(
                2, _paloadf
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.PALOADSTR: ICInfo(
                2, _paloadstr
            ),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.FPLOADSTR: ICInfo(2, _fploadstr),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
            ICInstruction.EXCHG: ICInfo(0, _exchg),  # Exchange registers
            ICInstruction.NOP: ICInfo(0, _nop),  # Used to remove (overwrite) instructions during the opt. phase
            ICInstruction.VAR: ICInfo(2, _var),  # Declares a variable space (filled with zeroes)
            ICInstruction.VARX: ICInfo(
                3, _varx
            ),  # Like the above but with a list of items (chars, bytes or words, hex)
            ICInstruction.VARD: ICInfo(
                2, _vard
            ),  # Like the above but with a list of items (chars, bytes or words, hex)
            ICInstruction.LVARX: ICInfo(
                3,
                _lvarx,
            ),  # Initializes a local variable. lvard X, (list of bytes): Initializes variable at offset X
            ICInstruction.LVARD: ICInfo(
                2,
                _lvard,
            ),  # Initializes a local variable. lvard X, (list of bytes): Initializes variable at offset X
            ICInstruction.LARRD: ICInfo(5, _larrd),  # Initializes a local array
            ICInstruction.MEMCOPY: ICInfo(
                3, _memcopy
            ),  # Copies a block of param 3 bytes of memory from param 2 addr to param 1 addr.
            ICInstruction.BANDU8: ICInfo(3, _band8),  # x = A & B
            ICInstruction.BANDI8: ICInfo(3, _band8),  # x = A & B
            ICInstruction.BORU8: ICInfo(3, _bor8),  # x = A | B
            ICInstruction.BORI8: ICInfo(3, _bor8),  # x = A | B
            ICInstruction.BXORU8: ICInfo(3, _bxor8),  # x = A ^ B
            ICInstruction.BXORI8: ICInfo(3, _bxor8),  # x = A ^ B
            ICInstruction.BNOTI8: ICInfo(2, _bnot8),  # x = !A
            ICInstruction.BNOTU8: ICInfo(2, _bnot8),  # x = !A
            ICInstruction.BANDU16: ICInfo(3, _band16),  # x = A & B
            ICInstruction.BANDI16: ICInfo(3, _band16),  # x = A & B
            ICInstruction.BORU16: ICInfo(3, _bor16),  # x = A | B
            ICInstruction.BORI16: ICInfo(3, _bor16),  # x = A | B
            ICInstruction.BXORU16: ICInfo(3, _bxor16),  # x = A ^ B
            ICInstruction.BXORI16: ICInfo(3, _bxor16),  # x = A ^ B
            ICInstruction.BNOTU16: ICInfo(2, _bnot16),  # x = A ^ B
            ICInstruction.BNOTI16: ICInfo(2, _bnot16),  # x = A ^ B
            ICInstruction.BANDU32: ICInfo(3, _band32),  # x = A & B
            ICInstruction.BANDI32: ICInfo(3, _band32),  # x = A & B
            ICInstruction.BORU32: ICInfo(3, _bor32),  # x = A | B
            ICInstruction.BORI32: ICInfo(3, _bor32),  # x = A | B
            ICInstruction.BXORU32: ICInfo(3, _bxor32),  # x = A ^ B
            ICInstruction.BXORI32: ICInfo(3, _bxor32),  # x = A ^ B
            ICInstruction.BNOTU32: ICInfo(2, _bnot32),  # x = A ^ B
            ICInstruction.BNOTI32: ICInfo(2, _bnot32),  # x = A ^ B
        }

    def init(self) -> None:
        """Initializes this module"""

        common.init()
        self.MEMORY.clear()
        self._set_quad_table()

        # Default code ORG
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="org", type=int, default=32768)
        # Default HEAP SIZE (Dynamic memory) in bytes
        OPTIONS(
            Action.ADD_IF_NOT_DEFINED, name="heap_size", type=int, default=4768, ignore_none=True
        )  # A bit more than 4K
        # Default HEAP ADDRESS (Dynamic memory) address
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_address", type=int, default=None, ignore_none=False)
        # Labels for HEAP START (might not be used if not needed)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_start_label", type=str, default=f"{NAMESPACE}.ZXBASIC_MEM_HEAP")
        # Labels for HEAP SIZE (might not be used if not needed)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size_label", type=str, default=f"{NAMESPACE}.ZXBASIC_HEAP_SIZE")
        # Flag for headerless mode (No prologue / epilogue)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="headerless", type=bool, default=False, ignore_none=True)

        engine.main()  # inits the optimizer

    @staticmethod
    def emit_prologue() -> list[str]:
        """Program Start routine"""
        heap_init = [f"{common.DATA_LABEL}:"]
        output = [f"org {OPTIONS.org}"]

        if common.REQUIRES.intersection(common.MEMINITS) or f"{NAMESPACE}.__MEM_INIT" in common.INITS:
            heap_init.append("; Defines HEAP SIZE\n" + OPTIONS.heap_size_label + " EQU " + str(OPTIONS.heap_size))
            if OPTIONS.heap_address is None:
                heap_init.append(OPTIONS.heap_start_label + ":")
                heap_init.append("DEFS %s" % str(OPTIONS.heap_size))
            else:
                heap_init.append(
                    "; Defines HEAP ADDRESS\n" + OPTIONS.heap_start_label + " EQU %s" % OPTIONS.heap_address
                )

        heap_init.append(
            "; Defines USER DATA Length in bytes\n"
            + f"{NAMESPACE}.ZXBASIC_USER_DATA_LEN EQU {common.DATA_END_LABEL} - {common.DATA_LABEL}"
        )
        heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA_LEN EQU {NAMESPACE}.ZXBASIC_USER_DATA_LEN")
        heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA EQU {common.DATA_LABEL}")

        output.append("%s:" % common.START_LABEL)
        if OPTIONS.headerless:
            output.extend(heap_init)
            return output

        output.append("di")
        output.append("push ix")
        output.append("push iy")
        output.append("exx")
        output.append("push hl")
        output.append("exx")
        output.append("ld hl, 0")
        output.append("add hl, sp")
        output.append(f"ld ({common.CALL_BACK}), hl")
        output.append("ei")

        output.extend(f"call {x}" for x in sorted(common.INITS))

        output.append(f"jp {common.MAIN_LABEL}")
        output.append(f"{common.CALL_BACK}:")
        output.append("DEFW 0")
        output.extend(heap_init)

        return output

    @staticmethod
    def emit_cast_to_bool():
        """Convert a byte value to boolean (0 or 1) if
        the global flag strictBool is True
        """
        if not OPTIONS.strict_bool:
            return []

        return ["pop af", runtime_call(RuntimeLabel.NORMALIZE_BOOLEAN), "push af"]

    @staticmethod
    def emit_epilogue() -> list[str]:
        """This special ending autoinitializes required inits
        (mainly alloc.asm) and changes the MEMORY initial address if it is
        ORG XXXX to ORG XXXX + heap size
        """
        output = []
        output.extend(common.AT_END)

        if OPTIONS.autorun:
            output.append(f"END {common.START_LABEL}")
        else:
            output.append("END")

        return output

    @staticmethod
    def remove_unused_labels(output: list[str]) -> None:
        """Removes unused labels from the output (list of asm instructions)"""
        labels_used: dict[str, list[int]] = defaultdict(list)
        labels_to_delete: dict[str, int] = {}
        labels: set[str] = set()
        label_alias: dict[str, str] = {}

        prev = None
        for i, ins in enumerate(output):
            if ins and ins[-1] == ":":
                ins = ins[:-1]
                labels.add(ins)
                if prev is not None:
                    if prev not in TMP_LABELS and ins in TMP_LABELS or prev in label_alias:
                        label_alias[ins] = prev
                    else:
                        label_alias[prev] = ins
                prev = ins
            else:
                prev = None

        for i, ins in enumerate(output):
            try_label = ins[:-1]
            if try_label in TMP_LABELS:
                if try_label in labels_used:
                    labels_to_delete.pop(try_label, None)
                else:
                    labels_to_delete[try_label] = i
                continue

            for op in Asm.opers(ins):
                if op in labels:
                    new_label = op
                    while new_label in label_alias:
                        new_label = label_alias[new_label]

                    labels_used[new_label].append(i)
                    labels_to_delete.pop(new_label, None)

                    if new_label != op:
                        output[i] = re.sub(f"((?<![.a-zA-Z0-9_])){op.replace('.', '[.]')}(?=$|\\s)", new_label, ins)

        for i in sorted(labels_to_delete.values(), reverse=True):
            output.pop(i)

    @staticmethod
    def _output_join(output: list[str], new_chunk: list[str], *, optimize: bool) -> None:
        """Extends output instruction list
        performing a little peep-hole optimization (O1)
        """
        base_index = len(output)  # output length before extending it
        output.extend(new_chunk)

        if not optimize:
            return

        # Optimization patterns: at this point no more than -O2
        patterns = [x for x in engine.PATTERNS if x.level <= min(OPTIONS.optimization_level, 2)]

        idx = max(0, base_index - engine.MAXLEN)
        while idx < len(output):
            if not engine.apply_match(output, patterns, index=idx):  # Nothing changed
                idx += 1
            else:
                idx = max(0, idx - engine.MAXLEN)

    def emit(self, *, optimize: bool = True) -> list[str]:
        """Begin converting each quad instruction to asm
        by iterating over the "mem" array, and called its
        associated function. Each function returns an array of
        ASM instructions which will be appended to the
        'output' array
        """
        output: list[str] = []
        for quad in self.MEMORY:
            self._output_join(output, self._QUAD_TABLE[quad.instr].func(quad), optimize=optimize)
            # If it is a boolean operation convert it to 0/1 if the STRICT_BOOL flag is True
            if common.RE_BOOL.match(quad.instr):
                self._output_join(output, self.emit_cast_to_bool(), optimize=optimize)

        if optimize and OPTIONS.optimization_level > 1:
            self.remove_unused_labels(output)
            tmp = output
            output = []
            self._output_join(output, tmp, optimize=optimize)

        output.extend(f"#include once <{j}>" for j in sorted(common.REQUIRES))

        return output  # Caller will save its contents to a file, or whatever
