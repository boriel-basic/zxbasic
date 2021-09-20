#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et

import re

from collections import defaultdict

from typing import Dict, List, Set

from src.api.config import OPTIONS, Action

from src.arch.z80.backend.runtime.namespace import NAMESPACE
from src.arch.z80.optimizer.helpers import HI16, LO16
from src.arch.z80.optimizer.asm import Asm
from src.arch.z80.peephole import engine
from src.arch.z80.backend.runtime import Labels as RuntimeLabel

# 8 bit arithmetic functions
from ._8bit import _add8, _sub8, _mul8, _divu8, _divi8, _modu8, _modi8, _neg8, _abs8

# 8 bit parameters and function call instrs
from ._8bit import _load8, _store8, _jzero8, _jnzero8, _jgezerou8, _jgezeroi8, _ret8, _param8, _fparam8

# 8 bit comparison functions
from ._8bit import _eq8, _lti8, _ltu8, _gti8, _gtu8, _ne8, _leu8, _lei8, _geu8, _gei8

# 8 bit boolean functions
from ._8bit import _or8, _and8, _not8, _xor8

# 8 bit shift operations
from ._8bit import _shru8, _shri8, _shl8

# 8 bit bitwise operations
from ._8bit import _bor8, _band8, _bnot8, _bxor8

# 16 bit arithmetic functions
from ._16bit import _add16, _sub16, _mul16, _divu16, _divi16, _modu16, _modi16, _neg16, _abs16, _jnzero16

# 16bit parameters and function call instrs
from ._16bit import _load16, _store16, _jzero16, _jgezerou16, _jgezeroi16, _ret16, _param16, _fparam16

# 16 bit comparison functions
from ._16bit import _eq16, _lti16, _ltu16, _gti16, _gtu16, _ne16, _leu16, _lei16, _geu16, _gei16

# 16 bit boolean functions
from ._16bit import _or16, _and16, _not16, _xor16

# 16 bit shift operations
from ._16bit import _shru16, _shri16, _shl16

# 16 bit bitwise operations
from ._16bit import _band16, _bor16, _bxor16, _bnot16

# 32 bit arithmetic functions
from ._32bit import _add32, _sub32, _mul32, _divu32, _divi32, _modu32, _modi32, _neg32, _abs32, _jnzero32

# 32 bit parameters and function call instrs
from ._32bit import _load32, _store32, _jzero32, _jgezerou32, _jgezeroi32, _ret32, _param32, _fparam32

# 32 bit comparison functions
from ._32bit import _eq32, _lti32, _ltu32, _gti32, _gtu32, _ne32, _leu32, _lei32, _geu32, _gei32

# 32 bit boolean functions
from ._32bit import _or32, _and32, _not32, _xor32

# 32 bit shift operations
from ._32bit import _shru32, _shri32, _shl32

# 32 bit bitwise operations
from ._32bit import _band32, _bor32, _bxor32, _bnot32

# Fixed Point arithmetic functions
from ._f16 import _addf16, _subf16, _mulf16, _divf16, _modf16, _negf16, _absf16

# f16 parameters and function call instrs
from ._f16 import _loadf16, _storef16, _jzerof16, _jnzerof16, _jgezerof16, _retf16, _paramf16, _fparamf16

# Fixed Point comparison functions
from ._f16 import _eqf16, _ltf16, _gtf16, _nef16, _lef16, _gef16

# Fixed Point boolean functions
from ._f16 import _orf16, _andf16, _notf16, _xorf16

# Floating Point arithmetic functions
from ._float import _addf, _subf, _mulf, _divf, _modf, _negf, _powf, _absf

# Floating Point parameters and function call instrs
from ._float import _loadf, _storef, _jzerof, _jnzerof, _jgezerof, _retf, _paramf, _fparamf, _fpop

# Floating Point comparison functions
from ._float import _eqf, _ltf, _gtf, _nef, _lef, _gef

# Floating Point boolean functions
from ._float import _orf, _andf, _notf, _xorf

# String arithmetic functions
from ._str import _addstr, _loadstr, _storestr, _jzerostr, _jnzerostr, _retstr, _paramstr, _fparamstr

# String comparison functions
from ._str import _ltstr, _gtstr, _eqstr, _lestr, _gestr, _nestr, _lenstr

# Param load and store instructions
from ._pload import _pload8, _pload16, _pload32, _ploadf, _ploadstr, _fploadstr
from ._pload import _pstore8, _pstore16, _pstore32, _pstoref16, _pstoref, _pstorestr
from ._pload import _paddr

from src.arch.z80.backend import common

from src.arch.z80.backend.common import MEMORY, LABEL_COUNTER, TMP_LABELS, TMP_COUNTER, TMP_STORAGES, REQUIRES
from src.arch.z80.backend.common import CALL_BACK, MAIN_LABEL, DATA_LABEL, DATA_END_LABEL, MEMINITS, RE_BOOL, AT_END
from src.arch.z80.backend.common import INITS, START_LABEL, QUADS, runtime_call, tmp_label, Quad, ICInfo

# Array store and load instructions
from ._array import _aload8, _aload16, _aload32, _aloadf, _aloadstr
from ._array import _astore8, _astore16, _astore32, _astoref16, _astoref, _astorestr
from ._array import _aaddr

# Array store and load instructions
from ._parray import _paload8, _paload16, _paload32, _paloadf, _paloadstr
from ._parray import _pastore8, _pastore16, _pastore32, _pastoref16, _pastoref, _pastorestr
from ._parray import _paaddr

from .generic import _nop, _org, _exchg, _end, _label, _deflabel, _data, _var, _varx, _vard, _lvarx, _lvard, _larrd
from .generic import _out, _in, _cast, _jump, _ret, _call, _leave, _enter, _memcopy, _inline


__all__ = [
    "tmp_label",
    "_fpop",
    "HI16",
    "INITS",
    "LO16",
    "LABEL_COUNTER",
    "MEMORY",
    "MEMINITS",
    "QUADS",
    "REQUIRES",
    "TMP_COUNTER",
    "TMP_STORAGES",
    "emit",
    "emit_end",
    "emit_start",
]

# Default code ORG
OPTIONS(Action.ADD_IF_NOT_DEFINED, name="org", type=int, default=32768)
# Default HEAP SIZE (Dynamic memory) in bytes
OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size", type=int, default=4768, ignore_none=True)  # A bit more than 4K


def init():
    """Initializes this module"""

    common.init()

    # Default code ORG
    OPTIONS(Action.ADD_IF_NOT_DEFINED, name="org", type=int, default=32768)
    # Default HEAP SIZE (Dynamic memory) in bytes
    OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size", type=int, default=4768, ignore_none=True)  # A bit more than 4K
    # Labels for HEAP START (might not be used if not needed)
    OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_start_label", type=str, default=f"{NAMESPACE}.ZXBASIC_MEM_HEAP")
    # Labels for HEAP SIZE (might not be used if not needed)
    OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size_label", type=str, default=f"{NAMESPACE}.ZXBASIC_HEAP_SIZE")
    # Flag for headerless mode (No prologue / epilogue)
    OPTIONS(Action.ADD_IF_NOT_DEFINED, name="headerless", type=bool, default=False, ignore_none=True)

    engine.main()  # inits the optimizer


# ------------------------------------------------------------------
# Lowlevel (to ASM) instructions implementation
# ------------------------------------------------------------------

QUADS.update(
    {
        "addu8": ICInfo(3, _add8),
        "addi8": ICInfo(3, _add8),
        "addi16": ICInfo(3, _add16),
        "addu16": ICInfo(3, _add16),
        "addi32": ICInfo(3, _add32),
        "addu32": ICInfo(3, _add32),
        "addf16": ICInfo(3, _addf16),
        "addf": ICInfo(3, _addf),
        "addstr": ICInfo(3, _addstr),
        "data": ICInfo(2, _data),
        "subi8": ICInfo(3, _sub8),
        "subu8": ICInfo(3, _sub8),
        "subi16": ICInfo(3, _sub16),
        "subu16": ICInfo(3, _sub16),
        "subi32": ICInfo(3, _sub32),
        "subu32": ICInfo(3, _sub32),
        "subf16": ICInfo(3, _subf16),
        "subf": ICInfo(3, _subf),
        "muli8": ICInfo(3, _mul8),
        "mulu8": ICInfo(3, _mul8),
        "muli16": ICInfo(3, _mul16),
        "mulu16": ICInfo(3, _mul16),
        "muli32": ICInfo(3, _mul32),
        "mulu32": ICInfo(3, _mul32),
        "mulf16": ICInfo(3, _mulf16),
        "mulf": ICInfo(3, _mulf),
        "divu8": ICInfo(3, _divu8),
        "divi8": ICInfo(3, _divi8),
        "divu16": ICInfo(3, _divu16),
        "divi16": ICInfo(3, _divi16),
        "divu32": ICInfo(3, _divu32),
        "divi32": ICInfo(3, _divi32),
        "divf16": ICInfo(3, _divf16),
        "divf": ICInfo(3, _divf),
        "powf": ICInfo(3, _powf),
        "modu8": ICInfo(3, _modu8),
        "modi8": ICInfo(3, _modi8),
        "modu16": ICInfo(3, _modu16),
        "modi16": ICInfo(3, _modi16),
        "modu32": ICInfo(3, _modu32),
        "modi32": ICInfo(3, _modi32),
        "modf16": ICInfo(3, _modf16),
        "modf": ICInfo(3, _modf),
        "shru8": ICInfo(3, _shru8),
        "shri8": ICInfo(3, _shri8),
        "shlu8": ICInfo(3, _shl8),
        "shli8": ICInfo(3, _shl8),
        "shru16": ICInfo(3, _shru16),
        "shri16": ICInfo(3, _shri16),
        "shlu16": ICInfo(3, _shl16),
        "shli16": ICInfo(3, _shl16),
        "shru32": ICInfo(3, _shru32),
        "shri32": ICInfo(3, _shri32),
        "shlu32": ICInfo(3, _shl32),
        "shli32": ICInfo(3, _shl32),
        "ltu8": ICInfo(3, _ltu8),
        "lti8": ICInfo(3, _lti8),
        "ltu16": ICInfo(3, _ltu16),
        "lti16": ICInfo(3, _lti16),
        "ltu32": ICInfo(3, _ltu32),
        "lti32": ICInfo(3, _lti32),
        "ltf16": ICInfo(3, _ltf16),
        "ltf": ICInfo(3, _ltf),
        "ltstr": ICInfo(3, _ltstr),
        "gtu8": ICInfo(3, _gtu8),
        "gti8": ICInfo(3, _gti8),
        "gtu16": ICInfo(3, _gtu16),
        "gti16": ICInfo(3, _gti16),
        "gtu32": ICInfo(3, _gtu32),
        "gti32": ICInfo(3, _gti32),
        "gtf16": ICInfo(3, _gtf16),
        "gtf": ICInfo(3, _gtf),
        "gtstr": ICInfo(3, _gtstr),
        "leu8": ICInfo(3, _leu8),
        "lei8": ICInfo(3, _lei8),
        "leu16": ICInfo(3, _leu16),
        "lei16": ICInfo(3, _lei16),
        "leu32": ICInfo(3, _leu32),
        "lei32": ICInfo(3, _lei32),
        "lef16": ICInfo(3, _lef16),
        "lef": ICInfo(3, _lef),
        "lestr": ICInfo(3, _lestr),
        "geu8": ICInfo(3, _geu8),
        "gei8": ICInfo(3, _gei8),
        "geu16": ICInfo(3, _geu16),
        "gei16": ICInfo(3, _gei16),
        "geu32": ICInfo(3, _geu32),
        "gei32": ICInfo(3, _gei32),
        "gef16": ICInfo(3, _gef16),
        "gef": ICInfo(3, _gef),
        "gestr": ICInfo(3, _gestr),
        "equ8": ICInfo(3, _eq8),
        "eqi8": ICInfo(3, _eq8),
        "equ16": ICInfo(3, _eq16),
        "eqi16": ICInfo(3, _eq16),
        "equ32": ICInfo(3, _eq32),
        "eqi32": ICInfo(3, _eq32),
        "eqf16": ICInfo(3, _eqf16),
        "eqf": ICInfo(3, _eqf),
        "eqstr": ICInfo(3, _eqstr),
        "neu8": ICInfo(3, _ne8),
        "nei8": ICInfo(3, _ne8),
        "neu16": ICInfo(3, _ne16),
        "nei16": ICInfo(3, _ne16),
        "neu32": ICInfo(3, _ne32),
        "nei32": ICInfo(3, _ne32),
        "nef16": ICInfo(3, _nef16),
        "nef": ICInfo(3, _nef),
        "nestr": ICInfo(3, _nestr),
        "absi8": ICInfo(2, _abs8),  # x = -x if x < 0
        "absi16": ICInfo(2, _abs16),  # x = -x if x < 0
        "absi32": ICInfo(2, _abs32),  # x = -x if x < 0
        "absf16": ICInfo(2, _absf16),  # x = -x if x < 0
        "absf": ICInfo(2, _absf),  # x = -x if x < 0
        "negu8": ICInfo(2, _neg8),  # x = -y
        "negi8": ICInfo(2, _neg8),  # x = -y
        "negu16": ICInfo(2, _neg16),  # x = -y
        "negi16": ICInfo(2, _neg16),  # x = -y
        "negu32": ICInfo(2, _neg32),  # x = -y
        "negi32": ICInfo(2, _neg32),  # x = -y
        "negf16": ICInfo(2, _negf16),  # x = -y
        "negf": ICInfo(2, _negf),  # x = -y
        "andu8": ICInfo(3, _and8),  # x = A and B
        "andi8": ICInfo(3, _and8),  # x = A and B
        "andu16": ICInfo(3, _and16),  # x = A and B
        "andi16": ICInfo(3, _and16),  # x = A and B
        "andu32": ICInfo(3, _and32),  # x = A and B
        "andi32": ICInfo(3, _and32),  # x = A and B
        "andf16": ICInfo(3, _andf16),  # x = A and B
        "andf": ICInfo(3, _andf),  # x = A and B
        "oru8": ICInfo(3, _or8),  # x = A or B
        "ori8": ICInfo(3, _or8),  # x = A or B
        "oru16": ICInfo(3, _or16),  # x = A or B
        "ori16": ICInfo(3, _or16),  # x = A or B
        "oru32": ICInfo(3, _or32),  # x = A or B
        "ori32": ICInfo(3, _or32),  # x = A or B
        "orf16": ICInfo(3, _orf16),  # x = A or B
        "orf": ICInfo(3, _orf),  # x = A or B
        "xoru8": ICInfo(3, _xor8),  # x = A xor B
        "xori8": ICInfo(3, _xor8),  # x = A xor B
        "xoru16": ICInfo(3, _xor16),  # x = A xor B
        "xori16": ICInfo(3, _xor16),  # x = A xor B
        "xoru32": ICInfo(3, _xor32),  # x = A xor B
        "xori32": ICInfo(3, _xor32),  # x = A xor B
        "xorf16": ICInfo(3, _xorf16),  # x = A xor B
        "xorf": ICInfo(3, _xorf),  # x = A xor B
        "notu8": ICInfo(2, _not8),  # x = not B
        "noti8": ICInfo(2, _not8),  # x = not B
        "notu16": ICInfo(2, _not16),  # x = not B
        "noti16": ICInfo(2, _not16),  # x = not B
        "notu32": ICInfo(2, _not32),  # x = not B
        "noti32": ICInfo(2, _not32),  # x = not B
        "notf16": ICInfo(2, _notf16),  # x = not B
        "notf": ICInfo(2, _notf),  # x = not B
        "jump": ICInfo(1, _jump),  # jmp LABEL
        "lenstr": ICInfo(2, _lenstr),  # Gets strlen
        "jzeroi8": ICInfo(2, _jzero8),  # if X == 0 jmp LABEL
        "jzerou8": ICInfo(2, _jzero8),  # if X == 0 jmp LABEL
        "jzeroi16": ICInfo(2, _jzero16),  # if X == 0 jmp LABEL
        "jzerou16": ICInfo(2, _jzero16),  # if X == 0 jmp LABEL
        "jzeroi32": ICInfo(2, _jzero32),  # if X == 0 jmp LABEL (32bit, fixed)
        "jzerou32": ICInfo(2, _jzero32),  # if X == 0 jmp LABEL (32bit, fixed)
        "jzerof16": ICInfo(2, _jzerof16),  # if X == 0 jmp LABEL (32bit, fixed)
        "jzerof": ICInfo(2, _jzerof),  # if X == 0 jmp LABEL (float)
        "jzerostr": ICInfo(2, _jzerostr),  # if str is NULL or len(str) == 0, jmp LABEL
        "jnzeroi8": ICInfo(2, _jnzero8),  # if X != 0 jmp LABEL
        "jnzerou8": ICInfo(2, _jnzero8),  # if X != 0 jmp LABEL
        "jnzeroi16": ICInfo(2, _jnzero16),  # if X != 0 jmp LABEL
        "jnzerou16": ICInfo(2, _jnzero16),  # if X != 0 jmp LABEL
        "jnzeroi32": ICInfo(2, _jnzero32),  # if X != 0 jmp LABEL (32bit, fixed)
        "jnzerou32": ICInfo(2, _jnzero32),  # if X != 0 jmp LABEL (32bit, fixed)
        "jnzerof16": ICInfo(2, _jnzerof16),  # if X != 0 jmp LABEL (32bit, fixed)
        "jnzerof": ICInfo(2, _jnzerof),  # if X != 0 jmp LABEL (float)
        "jnzerostr": ICInfo(2, _jnzerostr),  # if str is not NULL and len(str) > 0, jmp LABEL
        "jgezeroi8": ICInfo(2, _jgezeroi8),  # if X >= 0 jmp LABEL
        "jgezerou8": ICInfo(2, _jgezerou8),  # if X >= 0 jmp LABEL (ALWAYS TRUE)
        "jgezeroi16": ICInfo(2, _jgezeroi16),  # if X >= 0 jmp LABEL
        "jgezerou16": ICInfo(2, _jgezerou16),  # if X >= 0 jmp LABEL (ALWAYS TRUE)
        "jgezeroi32": ICInfo(2, _jgezeroi32),  # if X >= 0 jmp LABEL (32bit, fixed)
        "jgezerou32": ICInfo(2, _jgezerou32),  # if X >= 0 jmp LABEL (32bit, fixed) (always true)
        "jgezerof16": ICInfo(2, _jgezerof16),  # if X >= 0 jmp LABEL (32bit, fixed)
        "jgezerof": ICInfo(2, _jgezerof),  # if X >= 0 jmp LABEL (float)
        "paramu8": ICInfo(1, _param8),  # Push 8 bit param onto the stack
        "parami8": ICInfo(1, _param8),  # Push 8 bit param onto the stack
        "paramu16": ICInfo(1, _param16),  # Push 16 bit param onto the stack
        "parami16": ICInfo(1, _param16),  # Push 16 bit param onto the stack
        "paramu32": ICInfo(1, _param32),  # Push 32 bit param onto the stack
        "parami32": ICInfo(1, _param32),  # Push 32 bit param onto the stack
        "paramf16": ICInfo(1, _paramf16),  # Push 32 bit param onto the stack
        "paramf": ICInfo(1, _paramf),  # Push float param - 6 BYTES (always even) onto the stack
        "paramstr": ICInfo(1, _paramstr),  # Push float param - 6 BYTES (always even) onto the stack
        "fparamu8": ICInfo(1, _fparam8),  # __FASTCALL__ parameter
        "fparami8": ICInfo(1, _fparam8),  # __FASTCALL__ parameter
        "fparamu16": ICInfo(1, _fparam16),  # __FASTCALL__ parameter
        "fparami16": ICInfo(1, _fparam16),  # __FASTCALL__ parameter
        "fparamu32": ICInfo(1, _fparam32),  # __FASTCALL__ parameter
        "fparami32": ICInfo(1, _fparam32),  # __FASTCALL__ parameter
        "fparamf16": ICInfo(1, _fparamf16),  # __FASTCALL__ parameter
        "fparamf": ICInfo(1, _fparamf),  # __FASTCALL__ parameter
        "fparamstr": ICInfo(1, _fparamstr),  # __FASTCALL__ parameter
        "call": ICInfo(2, _call),  # Call Address, NNNN - NNNN = Size (in bytes) of the returned value (0 for procedure)
        "ret": ICInfo(1, _ret),  # Returns from a function call (enters the 'leave' sequence'), returning no value
        "reti8": ICInfo(2, _ret8),  # Returns from a function call (enters the 'leave' sequence'), returning 8 bit value
        "retu8": ICInfo(2, _ret8),  # Returns from a function call (enters the 'leave' sequence'), returning 8 bit value
        "reti16": ICInfo(2, _ret16),  # Returns from a func call (enters the 'leave' sequence'), returning 16 bit value
        "retu16": ICInfo(2, _ret16),  # Returns from a func call (enters the 'leave' sequence'), returning 16 bit value
        "reti32": ICInfo(2, _ret32),  # Returns from a func call (enters the 'leave' sequence'), returning 32 bit value
        "retu32": ICInfo(2, _ret32),  # Returns from a func call (enters the 'leave' sequence'), returning 32 bit value
        "retf16": ICInfo(2, _retf16),  # Returns from a func call (enters the 'leave' sequence'), returning fixed point
        "retf": ICInfo(2, _retf),  # Returns from a function call (enters the 'leave' sequence'), returning fixed point
        "retstr": ICInfo(2, _retstr),  # Returns from a func call (enters the 'leave' sequence'), returning fixed point
        "leave": ICInfo(1, _leave),  # LEAVE label, NN -> NN = Size of parameters in bytes (End of function <label>)
        "enter": ICInfo(1, _enter),  # ENTER proc/func; NN = size of local variables in bytes (Function beginning)
        "org": ICInfo(1, _org),  # Defines code location
        "end": ICInfo(1, _end),  # Defines an end sequence
        "label": ICInfo(1, _label),  # Defines a label # Flow control instructions
        "deflabel": ICInfo(2, _deflabel),  # Defines a label with a value
        "out": ICInfo(2, _out),  # Defines a OUT instruction OUT x, y
        "in": ICInfo(1, _in),  # Defines an IN instruction IN x, y
        "inline": ICInfo(1, _inline),  # Defines an inline asm instruction
        "cast": ICInfo(4, _cast),
        # TYPECAST: X = cast(from Type1, to Type2, Y) Ej. Converts Y 16bit to X 8bit: (cast, x, u16, u8, y)
        "storei8": ICInfo(2, _store8),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
        "storeu8": ICInfo(2, _store8),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
        "storei16": ICInfo(2, _store16),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
        "storeu16": ICInfo(2, _store16),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
        "storei32": ICInfo(2, _store32),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
        "storeu32": ICInfo(2, _store32),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
        "storef16": ICInfo(2, _storef16),  # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
        "storef": ICInfo(2, _storef),
        "storestr": ICInfo(2, _storestr),  # STORE STR1 <-- STR2 : Store string: Reallocs STR1 and copies STR2 into STR1
        "astorei8": ICInfo(2, _astore8),  # ARRAY STORE nnnn, X -> Stores X at position N (Type of X determines X size)
        "astoreu8": ICInfo(2, _astore8),  # ARRAY STORE nnnn, X -> Stores X at position N (Type of X determines X size)
        "astorei16": ICInfo(2, _astore16),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
        "astoreu16": ICInfo(2, _astore16),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
        "astorei32": ICInfo(2, _astore32),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
        "astoreu32": ICInfo(2, _astore32),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
        "astoref16": ICInfo(2, _astoref16),  # ARRAY STORE nnnn, X -> Stores X at pos N (Type of X determines X size)
        "astoref": ICInfo(2, _astoref),
        "astorestr": ICInfo(2, _astorestr),
        # ARRAY STORE STR1 <-- STR2 : Store string: Reallocs STR1 and then copies STR2 into STR1
        "loadi8": ICInfo(2, _load8),  # LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
        "loadu8": ICInfo(2, _load8),  # LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
        "loadi16": ICInfo(2, _load16),  # LOAD X, nnnn  -> Load memory content at nnnn into X
        "loadu16": ICInfo(2, _load16),  # LOAD X, nnnn  -> Load memory content at nnnn into X
        "loadi32": ICInfo(2, _load32),  # LOAD X, nnnn  -> Load memory content at nnnn into X
        "loadu32": ICInfo(2, _load32),  # LOAD X, nnnn  -> Load memory content at nnnn into X
        "loadf16": ICInfo(2, _loadf16),  # LOAD X, nnnn  -> Load memory content at nnnn into X
        "loadf": ICInfo(2, _loadf),  # LOAD X, nnnn  -> Load memory content at nnnn into X
        "loadstr": ICInfo(2, _loadstr),  # LOAD X, nnnn -> Load string value at nnnn into X
        "aloadi8": ICInfo(2, _aload8),  # ARRAY LOAD X, nnnn -> Load mem content at nnnn into X (X must be a temporal)
        "aloadu8": ICInfo(2, _aload8),  # ARRAY LOAD X, nnnn -> Load mem content at nnnn into X (X must be a temporal)
        "aloadi16": ICInfo(2, _aload16),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
        "aloadu16": ICInfo(2, _aload16),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
        "aloadi32": ICInfo(2, _aload32),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
        "aloadu32": ICInfo(2, _aload32),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
        "aloadf16": ICInfo(2, _aload32),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
        "aloadf": ICInfo(2, _aloadf),  # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
        "aloadstr": ICInfo(2, _aloadstr),  # ARRAY LOAD X, nnnn -> Load string value at nnnn into X
        "pstorei8": ICInfo(2, _pstore8),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pstoreu8": ICInfo(2, _pstore8),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pstorei16": ICInfo(2, _pstore16),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pstoreu16": ICInfo(2, _pstore16),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pstorei32": ICInfo(2, _pstore32),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pstoreu32": ICInfo(2, _pstore32),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pstoref16": ICInfo(2, _pstoref16),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pstoref": ICInfo(2, _pstoref),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pstorestr": ICInfo(2, _pstorestr),  # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastorei8": ICInfo(2, _pastore8),
        # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastoreu8": ICInfo(2, _pastore8),
        # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastorei16": ICInfo(2, _pastore16),
        # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastoreu16": ICInfo(2, _pastore16),
        # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastorei32": ICInfo(2, _pastore32),
        # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastoreu32": ICInfo(2, _pastore32),
        # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastoref16": ICInfo(2, _pastoref16),
        # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastoref": ICInfo(
            2,
            _pastoref,
        ),  # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "pastorestr": ICInfo(2, _pastorestr),
        # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
        "ploadi8": ICInfo(2, _pload8),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "ploadu8": ICInfo(2, _pload8),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "ploadi16": ICInfo(2, _pload16),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "ploadu16": ICInfo(2, _pload16),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "ploadi32": ICInfo(2, _pload32),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "ploadu32": ICInfo(2, _pload32),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "ploadf16": ICInfo(2, _pload32),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "ploadf": ICInfo(2, _ploadf),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "ploadstr": ICInfo(2, _ploadstr),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paddr": ICInfo(2, _paddr),  # LOADS IX + nnnn into the stack
        "aaddr": ICInfo(2, _aaddr),  # LOADS ADDRESS of global ARRAY element into the stack
        "paaddr": ICInfo(2, _paaddr),  # LOADS ADDRESS of local ARRAY element into the stack
        "paloadi8": ICInfo(2, _paload8),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paloadu8": ICInfo(2, _paload8),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paloadi16": ICInfo(2, _paload16),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paloadu16": ICInfo(2, _paload16),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paloadi32": ICInfo(2, _paload32),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paloadu32": ICInfo(2, _paload32),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paloadf16": ICInfo(2, _paload32),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paloadf": ICInfo(2, _paloadf),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "paloadstr": ICInfo(2, _paloadstr),  # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "fploadstr": ICInfo(2, _fploadstr),  # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
        "exchg": ICInfo(0, _exchg),  # Exchange registers
        "nop": ICInfo(0, _nop),  # Used to remove (overwrite) instructions during the opt. phase
        "var": ICInfo(2, _var),  # Declares a variable space (filled with zeroes)
        "varx": ICInfo(3, _varx),  # Like the above but with a list of items (chars, bytes or words, hex)
        "vard": ICInfo(2, _vard),  # Like the above but with a list of items (chars, bytes or words, hex)
        "lvarx": ICInfo(
            3,
            _lvarx,
        ),  # Initializes a local variable. lvard X, (list of bytes): Initializes variable at offset X
        "lvard": ICInfo(
            2,
            _lvard,
        ),  # Initializes a local variable. lvard X, (list of bytes): Initializes variable at offset X
        "larrd": ICInfo(5, _larrd),  # Initializes a local array
        "memcopy": ICInfo(3, _memcopy),  # Copies a block of param 3 bytes of memory from param 2 addr to param 1 addr.
        "bandu8": ICInfo(3, _band8),  # x = A & B
        "bandi8": ICInfo(3, _band8),  # x = A & B
        "boru8": ICInfo(3, _bor8),  # x = A | B
        "bori8": ICInfo(3, _bor8),  # x = A | B
        "bxoru8": ICInfo(3, _bxor8),  # x = A ^ B
        "bxori8": ICInfo(3, _bxor8),  # x = A ^ B
        "bnoti8": ICInfo(2, _bnot8),  # x = !A
        "bnotu8": ICInfo(2, _bnot8),  # x = !A
        "bandu16": ICInfo(3, _band16),  # x = A & B
        "bandi16": ICInfo(3, _band16),  # x = A & B
        "boru16": ICInfo(3, _bor16),  # x = A | B
        "bori16": ICInfo(3, _bor16),  # x = A | B
        "bxoru16": ICInfo(3, _bxor16),  # x = A ^ B
        "bxori16": ICInfo(3, _bxor16),  # x = A ^ B
        "bnotu16": ICInfo(2, _bnot16),  # x = A ^ B
        "bnoti16": ICInfo(2, _bnot16),  # x = A ^ B
        "bandu32": ICInfo(3, _band32),  # x = A & B
        "bandi32": ICInfo(3, _band32),  # x = A & B
        "boru32": ICInfo(3, _bor32),  # x = A | B
        "bori32": ICInfo(3, _bor32),  # x = A | B
        "bxoru32": ICInfo(3, _bxor32),  # x = A ^ B
        "bxori32": ICInfo(3, _bxor32),  # x = A ^ B
        "bnotu32": ICInfo(2, _bnot32),  # x = A ^ B
        "bnoti32": ICInfo(2, _bnot32),  # x = A ^ B
    }
)


# -------------------------
# Program Start routine
# -------------------------
def emit_start():
    output = list()
    heap_init = ["%s:" % DATA_LABEL]
    output.append("org %s" % OPTIONS.org)

    if REQUIRES.intersection(MEMINITS) or f"{NAMESPACE}.__MEM_INIT" in INITS:
        heap_init.append("; Defines HEAP SIZE\n" + OPTIONS.heap_size_label + " EQU " + str(OPTIONS.heap_size))
        heap_init.append(OPTIONS.heap_start_label + ":")
        heap_init.append("DEFS %s" % str(OPTIONS.heap_size))

    heap_init.append(
        "; Defines USER DATA Length in bytes\n"
        + f"{NAMESPACE}.ZXBASIC_USER_DATA_LEN EQU {DATA_END_LABEL} - {DATA_LABEL}"
    )
    heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA_LEN EQU {NAMESPACE}.ZXBASIC_USER_DATA_LEN")
    heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA EQU {DATA_LABEL}")

    output.append("%s:" % START_LABEL)
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
    output.append("ld (%s), hl" % CALL_BACK)
    output.append("ei")

    for x in sorted(INITS):
        output.append("call %s" % x)

    output.append("jp %s" % MAIN_LABEL)
    output.append("%s:" % CALL_BACK)
    output.append("DEFW 0")
    output.extend(heap_init)

    return output


def convertToBool():
    """Convert a byte value to boolean (0 or 1) if
    the global flag strictBool is True
    """
    if not OPTIONS.strict_bool:
        return []

    return ["pop af", runtime_call(RuntimeLabel.NORMALIZE_BOOLEAN), "push af"]


def emit_end():
    """This special ending autoinitializes required inits
    (mainly alloc.asm) and changes the MEMORY initial address if it is
    ORG XXXX to ORG XXXX + heap size
    """
    output = []
    output.extend(AT_END)

    if OPTIONS.autorun:
        output.append("END %s" % START_LABEL)
    else:
        output.append("END")

    return output


def remove_unused_labels(output: List[str]):
    labels_used: Dict[str, List[int]] = defaultdict(list)
    labels_to_delete: Dict[str, int] = {}
    labels: Set[str] = set()
    label_alias: Dict[str, str] = {}

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


def emit(mem: List[Quad], optimize: bool = True) -> List[str]:
    """Begin converting each quad instruction to asm
    by iterating over the "mem" array, and called its
    associated function. Each function returns an array of
    ASM instructions which will be appended to the
    'output' array
    """
    # Optimization patterns: at this point no more than -O2
    patterns = [x for x in engine.PATTERNS if x.level <= min(OPTIONS.optimization_level, 2)]

    def output_join(output: List[str], new_chunk: List[str]):
        """Extends output instruction list
        performing a little peep-hole optimization (O1)
        """
        base_index = len(output)
        output.extend(new_chunk)

        if not optimize:
            return

        idx = max(0, base_index - engine.MAXLEN)

        while idx < len(output):
            if not engine.apply_match(output, patterns, index=idx):  # Nothing changed
                idx += 1
            else:
                idx = max(0, idx - engine.MAXLEN)

    output: List[str] = []
    for i in mem:
        output_join(output, QUADS[i.quad[0]][1](i))
        if RE_BOOL.match(i.quad[0]):  # If it is a boolean operation convert it to 0/1 if the STRICT_BOOL flag is True
            output_join(output, convertToBool())

    if optimize and OPTIONS.optimization_level > 1:
        remove_unused_labels(output)
        tmp = output
        output = []
        output_join(output, tmp)

    for j in sorted(REQUIRES):
        output.append("#include once <%s>" % j)

    return output  # Caller will save its contents to a file, or whatever
