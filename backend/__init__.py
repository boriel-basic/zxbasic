#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et

import math
import re

from . import errors
from .errors import InvalidICError as InvalidIC

# Local optimization Flags
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

# 8 bit arithmetic functions
from .__8bit import _add8, _sub8, _mul8, _divu8, _divi8, _modu8, _modi8, _neg8, _abs8
# 8 bit comparison functions
from .__8bit import _eq8, _lti8, _ltu8, _gti8, _gtu8, _ne8, _leu8, _lei8, _geu8, _gei8
# 8 bit boolean functions
from .__8bit import _or8, _and8, _not8, _xor8, _8bit_oper
# 8 bit shift operations
from .__8bit import _shru8, _shri8, _shl8
# 8 bit bitwise operations
from .__8bit import _bor8, _band8, _bnot8, _bxor8


# 16 bit arithmetic functions
from .__16bit import _add16, _sub16, _mul16, _divu16, _divi16, _modu16, _modi16, _neg16, _abs16
# 16 bit comparison functions
from .__16bit import _eq16, _lti16, _ltu16, _gti16, _gtu16, _ne16, _leu16, _lei16, _geu16, _gei16
# 16 bit boolean functions
from .__16bit import _or16, _and16, _not16, _xor16, _16bit_oper
# 16 bit shift operations
from .__16bit import _shru16, _shri16, _shl16
# 16 bit bitwise operations
from .__16bit import _band16, _bor16, _bxor16, _bnot16


# 32 bit arithmetic functions
from .__32bit import _add32, _sub32, _mul32, _divu32, _divi32, _modu32, _modi32, _neg32, _abs32
# 32 bit comparison functions
from .__32bit import _eq32, _lti32, _ltu32, _gti32, _gtu32, _ne32, _leu32, _lei32, _geu32, _gei32
# 32 bit boolean functions
from .__32bit import _or32, _and32, _not32, _xor32, _32bit_oper
# 32 bit shift operations
from .__32bit import _shru32, _shri32, _shl32
# 32 bit bitwise operations
from .__32bit import _band32, _bor32, _bxor32, _bnot32


# Fixed Point arithmetic functions
from .__f16 import _addf16, _subf16, _mulf16, _divf16, _modf16, _negf16, _absf16
# Fixed Point comparison functions
from .__f16 import _eqf16, _ltf16, _gtf16, _nef16, _lef16, _gef16
# Fixed Point boolean functions
from .__f16 import _orf16, _andf16, _notf16, _xorf16, _f16_oper

from .__f16 import f16 # Returns DE,HL of a decimal value


# Floating Point arithmetic functions
from .__float import _addf, _subf, _mulf, _divf, _modf, _negf, _powf, _absf
# Floating Point comparison functions
from .__float import _eqf, _ltf, _gtf, _nef, _lef, _gef
# Floating Point boolean functions
from .__float import _orf, _andf, _notf, _xorf, _float_oper, _fpush, _fpop


# String arithmetic functions
from .__str import _addstr
# String comparison functions
from .__str import _ltstr, _gtstr, _eqstr, _lestr, _gestr, _nestr, _str_oper, _lenstr


# Param load and store instructions
from .__pload import _pload8, _pload16, _pload32, _ploadf, _ploadstr, _fploadstr
from .__pload import _pstore8, _pstore16, _pstore32, _pstoref16, _pstoref, _pstorestr
from .__pload import _paddr


from .__common import MEMORY, LABEL_COUNTER, TMP_LABELS, TMP_COUNTER, TMP_STORAGES, REQUIRES, INITS
from .__common import is_int, is_float, tmp_label


# Array store and load instructions
from .__array import _aload8, _aload16, _aload32, _aloadf, _aloadstr
from .__array import _astore8, _astore16, _astore32, _astoref16, _astoref, _astorestr
from .__array import _aaddr


# Array store and load instructions
from .__parray import _paload8, _paload16, _paload32, _paloadf, _paloadstr
from .__parray import _pastore8, _pastore16, _pastore32, _pastoref16, _pastoref, _pastorestr
from .__parray import _paaddr


# External functions
from optimizer import oper, inst, condition, HI16, LO16, is_16bit_idx_register
from api.config import OPTIONS


# Label RegExp
RE_LABEL = re.compile('^[ \t]*[a-zA-Z_][_a-zA-Z\d]*:')


# Label for the program START end EXIT
START_LABEL = '__START_PROGRAM'
END_LABEL = '__END_PROGRAM'
CALL_BACK = '__CALL_BACK__'

# Labels for HEAP START (might not be used if not needed)
OPTIONS.add_option_if_not_defined('heap_start_label', str, 'ZXBASIC_MEM_HEAP')

# Labels for HEAP SIZE (might not be used if not needed)
OPTIONS.add_option_if_not_defined('heap_size_label', str, 'ZXBASIC_HEAP_SIZE')

# Whether to add AUTOSTART code
FLAG_autostart = False # Set this to true to add END %STARTLABEL

# Whether to use the FunctionExit scheme
FLAG_use_function_exit = False

# Whether an 'end' has already been emmitted
FLAG_end_emmitted = False

# Default code ORG
OPTIONS.add_option_if_not_defined('org', int, 32768)

# Default HEAP SIZE (Dynamic memory) in bytes
OPTIONS.add_option_if_not_defined('heap_size', int, 4768) # A bit more than 4K

# List of modules that, if included, should call MEM_INIT
MEMINITS = ['alloc.asm', 'loadstr.asm', 'storestr2.asm', 'storestr.asm', 'strcpy.asm',
        'string.asm', 'strslice.asm', 'strcat.asm']


# Internal data types definition, with its size in bytes, or -1 if it is variable (string)
# Compound types are only arrays, and have the t
YY_TYPES = {
    'u8': 1,   # 8 bit unsigned integer
    'u16': 2,  # 16 bit unsigned integer
    'u32': 4,  # 32 bit unsigned integer
    'i8': 1,   # 8 bit SIGNED integer
    'i16': 2,  # 16 bit SIGNED integer
    'i32': 4,  # 32 bit SIGNED integer
    'f16': 4,  # -32768.9999 to 32767.9999 -aprox.- fixed point decimal (step = 1/2^16)
    'f': 5,    # Floating point
}

RE_BOOL = re.compile(r'^(eq|ne|lt|le|gt|ge|and|or|xor|not)(((u|i)(8|16|32))|(f16|f|str))$')

# CONSTAND LN(2)
__LN2 = math.log(2)

# This will be appended at the end  (useful for lvard, for example)
AT_END = []

# A table with ASM block entered by the USER (these won't be optimized)
ASMS = {}
ASMCOUNT = 0 # ASM blocks counter


def new_ASMID():
    ''' Returns a new unique ASM block id
    '''
    global ASMCOUNT

    result = '##ASM%i' % ASMCOUNT
    ASMCOUNT += 1 
    return result


def log2(x):
    ''' Returns log2(x)
    '''
    return math.log(x) / __LN2


def is_2n(x):
    ''' Returns true if x is an exact
    power of 2
    '''
    l = log2(x)
    return l == int(l)


def is_int_type(stype):
    ''' Returns whether a given type is integer
    '''
    return stype[0] in ('u', 'i')


def init_memory(mem):
    global MEMORY

    MEMORY = mem


# ------------------------------------------------------------------
# Typecast conversions
# ------------------------------------------------------------------

def to_byte(stype):
    ''' Returns the instruction sequence for converting from
    the given type to byte.
    '''
    output = []

    if stype in ('i8', 'u8'):
        return []

    if is_int_type(stype):
        output.append('ld a, l')
    elif stype == 'f16':
        output.append('ld a, e')
    elif stype == 'f': # Converts C ED LH to byte
        output.append('call __FTOU32REG')
        output.append('ld a, l')
        REQUIRES.add('ftou32reg.asm')

    return output


def to_word(stype):
    ''' Returns the instruction sequence for converting the given
    type stored in DE,HL to word (unsigned) HL.
    '''
    output = [] # List of instructions

    if stype == 'u8': # Byte to word
        output.append('ld l, a')
        output.append('ld h, 0')

    elif stype == 'i8': # Signed byte to word
        output.append('ld l, a')
        output.append('add a, a')
        output.append('sbc a, a')
        output.append('ld h, a')

    elif stype == 'f16': # Must MOVE HL into DE
        output.append('ex de, hl')

    elif stype == 'f':
        output.append('call __FTOU32REG')
        REQUIRES.add('ftou32reg.asm')

    return output


def to_long(stype):
    ''' Returns the instruction sequence for converting the given
    type stored in DE,HL to long (DE, HL).
    '''
    output = [] # List of instructions

    if stype in ('i8', 'u8', 'f16'): # Byte to word
        output = to_word(stype)

        if stype != 'f16': # If its a byte, just copy H to D,E
            output.append('ld e, h')
            output.append('ld d, h')

    if stype in ('i16', 'f16'): # Signed byte or fixed to word
        output.append('ld a, h')
        output.append('add a, a')
        output.append('sbc a, a')
        output.append('ld e, a')
        output.append('ld d, a')

    elif stype == 'u16':
        output.append('ld de, 0')

    elif stype == 'f':
        output.append('call __FTOU32REG')
        REQUIRES.add('ftou32reg.asm')

    return output


def to_fixed(stype):
    ''' Returns the instruction sequence for converting the given
    type stored in DE,HL to fixed DE,HL.
    '''
    output = [] # List of instructions

    if is_int_type(stype):
        output = to_word(stype)
        output.append('ex de, hl')
        output.append('ld hl, 0') # 'Truncate' the fixed point
    elif stype == 'f':
        output.append('call __FTOF16REG')
        REQUIRES.add('ftof16reg.asm')

    return output


def to_float(stype):
    ''' Returns the instruction sequence for converting the given
    type stored in DE,HL to fixed DE,HL.
    '''
    output = [] # List of instructions

    if stype == 'f':
        return [] # Nothing to do

    if stype == 'f16':
        output.append('call __F16TOFREG')
        REQUIRES.add('f16tofreg.asm')
        return output

    # If we reach this point, it's an integer type
    if stype == 'u8':
        output.append('call __U8TOFREG')
    elif stype == 'i8':
        output.append('call __I8TOFREG')
    else:
        output = to_long(stype)
        if stype in ('i16', 'i32'):
            output.append('call __I32TOFREG')
        else:
            output.append('call __U32TOFREG')

    REQUIRES.add('u32tofreg.asm')

    return output



# ------------------------------------------------------------------
# Lowlevel (to ASM) instructions implementation
# ------------------------------------------------------------------
def _nop(ins):
    ''' Returns nothing. (Ignored nop)
    '''
    return []


def _org(ins):
    ''' Outputs an origin of code.
    '''
    return ['org %s' % str(ins.quad[1])]


def _exchg(ins):
    ''' Exchange ALL registers. If the processor
    does not support this, it must be implemented saving registers in a memory
    location.
    '''
    output = []
    output.append('ex af, af\'')
    output.append('exx')
    return output


def _end(ins):
    ''' Outputs the ending sequence
    '''
    global FLAG_end_emmitted
    output = _16bit_oper(ins.quad[1])
    output.append('ld b, h')
    output.append('ld c, l')

    if FLAG_end_emmitted:
        return output + ['jp %s' % END_LABEL]

    FLAG_end_emmitted = True

    output.append('%s:' % END_LABEL)
    output.append('di')
    output.append('ld hl, (%s)' % CALL_BACK)
    output.append('ld sp, hl')
    output.append('exx')
    output.append('pop hl')
    output.append('exx')
    output.append('pop iy')
    output.append('pop ix')
    output.append('ei')
    output.append('ret')
    output.append('%s:' % CALL_BACK)
    output.append('DEFW 0')

    return output


def _label(ins):
    ''' Defines a Label.
    '''
    return ['%s:' % str(ins.quad[1])]


def _deflabel(ins):
    ''' Defines a Label with a value.
    '''
    return ['%s EQU %s' % (str(ins.quad[1]), str(ins.quad[2]))]


def _var(ins):
    ''' Defines a memory variable.
    '''
    output = []
    output.append('%s:' % ins.quad[1])
    output.append('DEFB %s' % ((int(ins.quad[2]) - 1) * '00, ' + '00'))

    return output


def _varx(ins):
    ''' Defines a memory space with a default CONSTANT expression
    1st parameter is the var name
    2nd parameter is the type-size (u8 or i8 for byte, u16 or i16 for word, etc)
    3rd parameter is the list of expressions. All of them will be converted to the
        type required.
    '''
    output = []
    output.append('%s:' % ins.quad[1])

    if ins.quad[2] in ('i8', 'u8'):
        size = 'B' 
    elif ins.quad[2] in ('i16', 'u16'):
        size = 'W'
    else:
        raise InvalidIC('Unimplemented vard size: %s' % ins.quad[2], ins.quad)
    
    q = eval(ins.quad[3])

    for x in q:
        output.append('DEF%s %s' % (size, x))

    return output


def _vard(ins):
    ''' Defines a memory space with a default set of bytes/words in hexadecimal
    Values with more than 2 digits represents a WORD (2 bytes) value.
    E.g. '01' => 0, '001' => 1, 0 bytes
    '''
    output = []
    output.append('%s:' % ins.quad[1])

    q = eval(ins.quad[2])

    for x in q:
        if len(x) <= 2:
            if x[0] > '9': # Not a number?
                x = '0' + x
            output.append('DEFB %sh' % x)
        else:
            if x[0] > '9': # Not a number?
                x = '0' + x
            output.append('DEFW %sh' % x)

    return output


def _lvarx(ins):
    ''' Defines a local variable. 1st param is offset of the local variable.
    2nd param is the typea list of bytes in hexadecimal.
    '''
    output = []

    l = eval(ins.quad[3]) # List of bytes to push
    label = tmp_label()
    offset = int(ins.quad[1])
    tmp = list(ins.quad)
    tmp[1] = label
    ins.quad = tmp
    AT_END.extend(_varx(ins))

    output.append('push ix')
    output.append('pop hl')
    output.append('ld bc, %i' % -offset)
    output.append('add hl, bc')
    output.append('ex de, hl')
    output.append('ld hl, %s' % label)
    output.append('ld bc, %i' % (len(l) * YY_TYPES[ins.quad[2]]))
    output.append('ldir')

    return output


def _lvard(ins):
    ''' Defines a local variable. 1st param is offset of the local variable.
    2nd param is a list of bytes in hexadecimal.
    '''
    output = []

    l = eval(ins.quad[2]) # List of bytes to push
    label = tmp_label()
    offset = int(ins.quad[1])
    tmp = list(ins.quad)
    tmp[1] = label
    ins.quad = tmp
    AT_END.extend(_vard(ins))

    output.append('push ix')
    output.append('pop hl')
    output.append('ld bc, %i' % -offset)
    output.append('add hl, bc')
    output.append('ex de, hl')
    output.append('ld hl, %s' % label)
    output.append('ld bc, %i' % len(l))
    output.append('ldir')

    return output


def _out(ins):
    ''' Translates OUT to asm.
    '''
    output = []

    value = ins.quad[2]
    try:
        value = int(value) & 255 # Converted to byte
        output.append('ld a, %i' % value)
    except ValueError:
        output.append('pop af')

    try:
        port = int(ins.quad[1]) & 0xFFFF # Converted to word
        output.append('ld bc, %i' % port)
    except ValueError:
        output.append('pop bc')

    output.append('out (c), a')

    return output


def _in(ins):
    ''' Translates IN to asm.
    '''
    output = []

    try:
        port = int(ins.quad[1]) & 0xFFFF # Converted to word
        output.append('ld bc, %i' % port)
    except ValueError:
        output.append('pop bc')

    output.append('in a, (c)')
    output.append('push af')

    return output


def _load8(ins):
    ''' Loads an 8 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _8bit_oper(ins.quad[2])
    output.append('push af')
    return output



def _load16(ins):
    ''' Loads a 16 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _16bit_oper(ins.quad[2])
    output.append('push hl')
    return output



def _load32(ins):
    ''' Load a 32 bit value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _32bit_oper(ins.quad[2])
    output.append('push de')
    output.append('push hl')
    return output



def _loadf16(ins):
    ''' Load a 32 bit (16.16) fixed point value from a memory address
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _f16_oper(ins.quad[2])
    output.append('push de')
    output.append('push hl')
    return output



def _loadf(ins):
    ''' Loads a floating point value from a memory address.
    If 2nd arg. start with '*', it is always treated as
    an indirect value.
    '''
    output = _float_oper(ins.quad[2])
    output.extend(_fpush())
    return output



def _loadstr(ins):
    ''' Loads a string value from a memory address.
    '''
    temporal, output = _str_oper(ins.quad[2], no_exaf = True)

    if not temporal:
        output.append('call __LOADSTR')
        REQUIRES.add('loadstr.asm')

    output.append('push hl')
    return output



def _store8(ins):
    ''' Stores 2nd operand content into address of 1st operand.
    store8 a, x =>  a = x
    Use '*' for indirect store on 1st operand.
    '''
    output = _8bit_oper(ins.quad[2])

    op = ins.quad[1]
    
    indirect = op[0] == '*'
    if indirect:
        op = op[1:]

    immediate = op[0] == '#'
    if immediate:
        op = op[1:]

    if is_int(op) or op[0] == '_':
        if is_int(op):
            op = str(int(op) & 0xFFFF)

        if immediate:
            if indirect:
                output.append('ld (%s), a' % op)
            else: # ???
                output.append('ld (%s), a' % op)
        elif indirect:
            output.append('ld hl, (%s)' % op)
            output.append('ld (hl), a')
        else:
            output.append('ld (%s), a' % op)
    else:
        if immediate:
            if indirect: # A label not starting with _
                output.append('ld hl, (%s)' % op)
                output.append('ld (hl), a')
            else:
                output.append('ld (%s), a' % op)
            return output
        else:
            output.append('pop hl')

        if indirect:
            output.append('ld e, (hl)')
            output.append('inc hl')
            output.append('ld d, (hl)')
            output.append('ld (de), a')
        else:
            output.append('ld (hl), a')

    return output



def _store16(ins):
    ''' Stores 2nd operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    Use '*' for indirect store on 1st operand.
    '''
    output = []
    output = _16bit_oper(ins.quad[2])

    try:
        value = ins.quad[1]
        indirect = False
        if value[0] == '*':
            indirect = True
            value = value[1:]

        value = int(value) & 0xFFFF
        if indirect:
            output.append('ex de, hl')
            output.append('ld hl, (%s)' % str(value))
            output.append('ld (hl), e')
            output.append('inc hl')
            output.append('ld (hl), d')
        else:
            output.append('ld (%s), hl' % str(value))
    except ValueError:
        if value[0] == '_':
            if indirect:
                output.append('ex de, hl')
                output.append('ld hl, (%s)' % str(value))
                output.append('ld (hl), e')
                output.append('inc hl')
                output.append('ld (hl), d')
            else:
                output.append('ld (%s), hl' % str(value))
        elif value[0] == '#':
            value = value[1:]
            if indirect:
                output.append('ex de, hl')
                output.append('ld hl, (%s)' % str(value))
                output.append('ld (hl), e')
                output.append('inc hl')
                output.append('ld (hl), d')
            else:
                output.append('ld (%s), hl' % str(value))
        else:
            output.append('ex de, hl')
            if indirect:
                output.append('pop hl')
                output.append('ld a, (hl)')
                output.append('inc hl')
                output.append('ld h, (hl)')
                output.append('ld l, a')
            else:
                output.append('pop hl')

            output.append('ld (hl), e')
            output.append('inc hl')
            output.append('ld (hl), d')

    return output


def _store32(ins):
    ''' Stores 2nd operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    '''
    op = ins.quad[1]
    
    indirect = op[0] == '*'
    if indirect:
        op = op[1:]

    immediate = op[0] == '#' # Might make no sense here?
    if immediate:
        op = op[1:]

    if is_int(op) or op[0] == '_' or immediate:
        output = _32bit_oper(ins.quad[2], preserveHL = indirect)

        if is_int(op):
            op = str(int(op) & 0xFFFF)

        if indirect:
            output.append('ld hl, (%s)' % op)
            output.append('call __STORE32')
            REQUIRES.add('store32.asm')

            return output

        output.append('ld (%s), hl' % op)
        output.append('ld (%s + 2), de' % op)

        return output

    output = _32bit_oper(ins.quad[2], preserveHL = True)
    output.append('pop hl')

    if indirect:
        output.append('call __ISTORE32')
        REQUIRES.add('store32.asm')

        return output

    output.append('call __STORE32')
    REQUIRES.add('store32.asm')

    return output


def _storef16(ins):
    ''' Stores 2º operand content into address of 1st operand.
    store16 a, x =>  *(&a) = x
    '''
    value = ins.quad[2]
    if is_float(value):
        val = float(ins.quad[2]) # Immediate?
        (de, hl) = f16(val)
        q = list(ins.quad)
        q[2] = (de << 16) | hl
        ins.quad = tuple(q)

    return _store32(ins)


def _storef(ins):
    ''' Stores a floating point value into a memory address.
    '''
    output = _float_oper(ins.quad[2])

    op = ins.quad[1]
    
    indirect = op[0] == '*'
    if indirect:
        op = op[1:]

    immediate = op[0] == '#' # Might make no sense here?
    if immediate:
        op = op[1:]

    if is_int(op) or op[0] == '_':
        if is_int(op):
            op = str(int(op) & 0xFFFF)

        if indirect:
            output.append('ld hl, (%s)' % op)
        else:
            output.append('ld hl, %s' % op)
    else:
        output.append('pop hl')
        if indirect:
            output.append('call __ISTOREF')
            REQUIRES.add('storef.asm')

            return output

    output.append('call __STOREF')
    REQUIRES.add('storef.asm')

    return output


def _storestr(ins):
    ''' Stores a string value into a memory address.
    It copies content of 2nd operand (string), into 1st, reallocating
    dynamic memory for the 1st str. These instruction DOES ALLOW
    inmediate strings for the 2nd parameter, starting with '#'.

    Must prepend '#' (immediate sigil) to 1st operand, as we need
    the & address of the destination.
    '''
    op1 = ins.quad[1]
    indirect = op1[0] == '*'    
    if indirect:
        op1 = op1[1:]

    immediate = op1[0] == '#'
    if immediate and not indirect:
        raise InvalidIC('storestr does not allow immediate destination', ins.quad)

    if not indirect:
        op1 = '#' + op1

    tmp1, tmp2, output = _str_oper(op1, ins.quad[2], no_exaf = True)

    if not tmp2:
        output.append('call __STORE_STR')
        REQUIRES.add('storestr.asm')
    else:
        output.append('call __STORE_STR2')
        REQUIRES.add('storestr2.asm')

    return output



def _cast(ins):
    ''' Convert data from typeA to typeB (only numeric data types)
    '''
    # Signed and unsigned types are the same in the Z80
    tA = ins.quad[2]  # From TypeA
    tB = ins.quad[3]  # To TypeB

    xsA = sA = YY_TYPES[tA]  # Type sizes
    xsB = sB = YY_TYPES[tB]  # Type sizes


    output = []
    if tA in ('u8', 'i8'):
        output.extend(_8bit_oper(ins.quad[4]))
    elif tA in ('u16', 'i16'):
        output.extend(_16bit_oper(ins.quad[4]))
    elif tA in ('u32', 'i32'):
        output.extend(_32bit_oper(ins.quad[4]))
    elif tA == 'f16':
        output.extend(_f16_oper(ins.quad[4]))
    elif tA == 'f':
        output.extend(_float_oper(ins.quad[4]))
    else: 
        raise errors.GenericError(
            'Internal error: invalid typecast from %s to %s' % (tA, tB))

    if tB in ('u8', 'i8'): # It was a byte
        output.extend(to_byte(tA))
    elif tB in ('u16', 'i16'):
        output.extend(to_word(tA))
    elif tB in ('u32', 'i32'):
        output.extend(to_long(tA))
    elif tB == 'f16':
        output.extend(to_fixed(tA))
    elif tB == 'f':
        output.extend(to_float(tA))

    xsB += sB % 2  # make it even (round up)

    if xsB > 4:
        output.extend(_fpush())
    else:
        if xsB > 2:
            output.append('push de')  # Fixed or 32 bit Integer

        if sB > 1:
            output.append('push hl')  # 16 bit Integer
        else:
            output.append('push af')  # 8 bit Integer

    return output


# ------------------- FLOW CONTROL instructions -------------------

def _jump(ins):
    ''' Jump to a label
    '''
    return ['jp %s' % str(ins.quad[1])]


def _jzero8(ins):
    ''' Jumps if top of the stack (8bit) is 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) == 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _8bit_oper(value)
    output.append('or a')
    output.append('jp z, %s' % str(ins.quad[2]))
    return output


def _jzero16(ins):
    ''' Jumps if top of the stack (16bit) is 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) == 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _16bit_oper(value)
    output.append('ld a, h')
    output.append('or l')
    output.append('jp z, %s' % str(ins.quad[2]))
    return output


def _jzero32(ins):
    ''' Jumps if top of the stack (32bit) is 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) == 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _32bit_oper(value)
    output.append('ld a, h')
    output.append('or l')
    output.append('or e')
    output.append('or d')
    output.append('jp z, %s' % str(ins.quad[2]))
    return output


def _jzerof16(ins):
    ''' Jumps if top of the stack (32bit) is 0 to arg(1)
    (For Fixed point 16.16 bit values)
    '''
    value = ins.quad[1]
    if is_float(value):
        if float(value) == 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _f16_oper(value)
    output.append('ld a, h')
    output.append('or l')
    output.append('or e')
    output.append('or d')
    output.append('jp z, %s' % str(ins.quad[2]))
    return output


def _jzerof(ins):
    ''' Jumps if top of the stack (40bit, float) is 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_float(value):
        if float(value) == 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _float_oper(value)
    output.append('ld a, c')
    output.append('or l')
    output.append('or h')
    output.append('or e')
    output.append('or d')
    output.append('jp z, %s' % str(ins.quad[2]))
    return output


def _jzerostr(ins):
    ''' Jumps if top of the stack contains a NULL pointer
        or its len is Zero
    '''
    output = []
    disposable = False    # True if string must be freed from memory

    if ins.quad[1][0] == '_': # Variable?
        output.append('ld hl, (%s)' % ins.quad[1][0])
    else:
        output.append('pop hl')
        output.append('push hl') # Saves it for later
        disposable = True

    output.append('call __STRLEN')

    if disposable:
        output.append('ex (sp), hl')
        output.append('call __MEM_FREE')
        output.append('pop hl')
        REQUIRES.add('alloc.asm')

    output.append('ld a, h')
    output.append('or l')
    output.append('jp z, %s' % str(ins.quad[2]))
    REQUIRES.add('strlen.asm')
    return output


def _jnzero8(ins):
    ''' Jumps if top of the stack (8bit) is != 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) != 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _8bit_oper(value)
    output.append('or a')
    output.append('jp nz, %s' % str(ins.quad[2]))
    return output


def _jnzero16(ins):
    ''' Jumps if top of the stack (16bit) is != 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) != 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _16bit_oper(value)
    output.append('ld a, h')
    output.append('or l')
    output.append('jp nz, %s' % str(ins.quad[2]))
    return output


def _jnzero32(ins):
    ''' Jumps if top of the stack (32bit) is !=0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) != 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _32bit_oper(value)
    output.append('ld a, h')
    output.append('or l')
    output.append('or e')
    output.append('or d')
    output.append('jp nz, %s' % str(ins.quad[2]))
    return output


def _jnzerof16(ins):
    ''' Jumps if top of the stack (32bit) is !=0 to arg(1)
    Fixed Point (16.16 bit) values.
    '''
    value = ins.quad[1]
    if is_float(value):
        if float(value) != 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _f16_oper(value)
    output.append('ld a, h')
    output.append('or l')
    output.append('or e')
    output.append('or d')
    output.append('jp nz, %s' % str(ins.quad[2]))
    return output


def _jnzerof(ins):
    ''' Jumps if top of the stack (40bit, float) is != 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_float(value):
        if float(value) != 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _float_oper(value)
    output.append('ld a, c')
    output.append('or l')
    output.append('or h')
    output.append('or e')
    output.append('or d')
    output.append('jp nz, %s' % str(ins.quad[2]))
    return output


def _jnzerostr(ins):
    ''' Jumps if top of the stack contains a string with
        at less 1 char
    '''
    output = []
    disposable = False    # True if string must be freed from memory

    if ins.quad[1][0] == '_': # Variable?
        output.append('ld hl, (%s)' % ins.quad[1][0])
    else:
        output.append('pop hl')
        output.append('push hl') # Saves it for later
        disposable = True

    output.append('call __STRLEN')

    if disposable:
        output.append('ex (sp), hl')
        output.append('call __MEM_FREE')
        output.append('pop hl')
        REQUIRES.add('alloc.asm')

    output.append('ld a, h')
    output.append('or l')
    output.append('jp nz, %s' % str(ins.quad[2]))

    REQUIRES.add('strlen.asm')

    return output


def _jgezerou8(ins):
    ''' Jumps if top of the stack (8bit) is >= 0 to arg(1)
        Always TRUE for unsigned
    '''
    output = []
    value = ins.quad[1]
    if not is_int(value):
        output = _8bit_oper(value)

    output.append('jp %s' % str(ins.quad[2]))
    return output


def _jgezeroi8(ins):
    ''' Jumps if top of the stack (8bit) is >= 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) >= 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _8bit_oper(value)
    output.append('add a, a') # Puts sign into carry
    output.append('jp nc, %s' % str(ins.quad[2]))
    return output


def _jgezerou16(ins):
    ''' Jumps if top of the stack (16bit) is >= 0 to arg(1)
        Always TRUE for unsigned
    '''
    output = []
    value = ins.quad[1]
    if not is_int(value):
        output = _16bit_oper(value)

    output.append('jp %s' % str(ins.quad[2]))
    return output


def _jgezeroi16(ins):
    ''' Jumps if top of the stack (16bit) is >= 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) >= 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _16bit_oper(value)
    output.append('add hl, hl') # Puts sign into carry
    output.append('jp nc, %s' % str(ins.quad[2]))
    return output


def _jgezerou32(ins):
    ''' Jumps if top of the stack (23bit) is >= 0 to arg(1)
        Always TRUE for unsigned
    '''
    output = []
    value = ins.quad[1]
    if not is_int(value):
        output = _32bit_oper(value)

    output.append('jp %s' % str(ins.quad[2]))
    return output


def _jgezeroi32(ins):
    ''' Jumps if top of the stack (32bit) is >= 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_int(value):
        if int(value) >= 0:
            return ['jp %s' % str(ins.quad[2])] # Always true
        else:
            return []

    output = _32bit_oper(value)
    output.append('ld a, d')
    output.append('add a, a') # Puts sign into carry
    output.append('jp nc, %s' % str(ins.quad[2]))
    return output


def _jgezerof16(ins):
    ''' Jumps if top of the stack (32bit, fixed point) is >= 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_float(value):
        if float(value) >= 0:
            return ['jp %s' % str(ins.quad[2])] # Always true

    output = _f16_oper(value)
    output.append('ld a, d')
    output.append('add a, a') # Puts sign into carry
    output.append('jp nc, %s' % str(ins.quad[2]))
    return output


def _jgezerof(ins):
    ''' Jumps if top of the stack (40bit, float) is >= 0 to arg(1)
    '''
    value = ins.quad[1]
    if is_float(value):
        if float(value) >= 0:
            return ['jp %s' % str(ins.quad[2])] # Always true

    output = _float_oper(value)
    output.append('ld a, e')  # Take sign from mantissa (bit 7)
    output.append('add a, a') # Puts sign into carry
    output.append('jp nc, %s' % str(ins.quad[2]))
    return output


def _ret(ins):
    ''' Returns from a procedure / function
    '''
    return ['jp %s' % str(ins.quad[1])]


def _ret8(ins):
    ''' Returns from a procedure / function an 8bits value
    '''
    output = _8bit_oper(ins.quad[1])
    output.append('jp %s' % str(ins.quad[2]))
    return output


def _ret16(ins):
    ''' Returns from a procedure / function a 16bits value
    '''
    output = _16bit_oper(ins.quad[1])
    output.append('jp %s' % str(ins.quad[2]))
    return output


def _ret32(ins):
    ''' Returns from a procedure / function a 32bits value (even Fixed point)
    '''
    output = _32bit_oper(ins.quad[1])
    output.append('jp %s' % str(ins.quad[2]))
    return output


def _retf16(ins):
    ''' Returns from a procedure / function a Fixed Point (32bits) value
    '''
    output = _f16_oper(ins.quad[1])
    output.append('jp %s' % str(ins.quad[2]))
    return output


def _retf(ins):
    ''' Returns from a procedure / function a Floating Point (40bits) value
    '''
    output = _float_oper(ins.quad[1])
    output.append('jp %s' % str(ins.quad[2]))
    return output


def _retstr(ins):
    ''' Returns from a procedure / function a string pointer (16bits) value
    '''
    tmp, output = _str_oper(ins.quad[1], no_exaf = True)

    if not tmp:
        output.append('call __LOADSTR')
        REQUIRES.add('loadstr.asm')

    output.append('jp %s' % str(ins.quad[2]))
    return output


def _call(ins):
    ''' Calls a function XXXX (or address XXXX)
    2nd parameter contains size of the returning result if any, and will be
    pushed onto the stack.
    '''
    output = []
    output.append('call %s' % str(ins.quad[1]))

    try:
        val = int(ins.quad[2])
        if val == 1:
            output.append('push af') # Byte
        else:
            if val > 4:
                output.extend(_fpush())
            else:
                if val > 2:
                    output.append('push de')
                if val > 1:
                    output.append('push hl')

    except ValueError:
        pass

    return output


def _leave(ins):
    ''' Return from a function popping N bytes from the stack
    Use '__fastcall__' as 1st parameter, to just return
    '''
    global FLAG_use_function_exit

    output = []

    if ins.quad[1] == '__fastcall__':
        output.append('ret')
        return output

    nbytes = int(ins.quad[1]) # Number of bytes to pop (params size)

    if nbytes == 0:
        output.append('ld sp, ix')
        output.append('pop ix')
        output.append('ret')

        return output

    if nbytes == 1:
        output.append('ld sp, ix')
        output.append('pop ix')
        output.append('inc sp') # "Pops" 1 byte
        output.append('ret')

        return output

    if nbytes <= 11: # Number of bytes it worth the hassle to "pop" off the stack
        output.append('ld sp, ix')
        output.append('pop ix')
        output.append('exx')
        output.append('pop hl')
        for i in range((nbytes >> 1) - 1):
            output.append('pop bc') # Removes (n * 2  - 2) bytes form the stack

        if nbytes & 1: # Odd?
            output.append('inc sp') # "Pops" 1 byte (This should never happens, since params are always even-sized)

        output.append('ex (sp), hl') # Place back return address
        output.append('exx')
        output.append('ret')

        return output

    if not FLAG_use_function_exit:
        FLAG_use_function_exit = True # Use standard exit
        output.append('exx')
        output.append('ld hl, %i' % nbytes)
        output.append('__EXIT_FUNCTION:')
        output.append('ld sp, ix')
        output.append('pop ix')
        output.append('pop de')
        output.append('add hl, sp')
        output.append('ld sp, hl')
        output.append('push de')
        output.append('exx')
        output.append('ret')
    else:
        output.append('exx')
        output.append('ld hl, %i' % nbytes)
        output.append('jp __EXIT_FUNCTION')

    return output


def _enter(ins):
    ''' Enter function sequence for doing a function start
        ins.quad[1] contains size (in bytes) of local variables
        Use '__fastcall__' as 1st parameter to prepare a fastcall
        function (no local variables).
    '''
    output = []

    if ins.quad[1] == '__fastcall__':
        return output

    output.append('push ix')
    output.append('ld ix, 0')
    output.append('add ix, sp')

    size_bytes = int(ins.quad[1])

    if size_bytes != 0:
        if size_bytes < 7:
            output.append('ld hl, 0')
            output.extend(['push hl'] * (size_bytes >> 1))

            if size_bytes % 2: # odd?
                output.append('push hl')
                output.append('inc sp')
        else:
            output.append('ld hl, -%i' % size_bytes) # "Pushes nn bytes"
            output.append('add hl, sp')
            output.append('ld sp, hl')
            output.append('ld (hl), 0')
            output.append('ld bc, %i' % (size_bytes - 1))
            output.append('ld d, h')
            output.append('ld e, l')
            output.append('inc de')
            output.append('ldir')        # Clear with ZEROs

    return output


def _param8(ins):
    ''' Pushes 8bit param into the stack
    '''
    output = _8bit_oper(ins.quad[1])
    output.append('push af')
    return output


def _param16(ins):
    ''' Pushes 16bit param into the stack
    '''
    output = _16bit_oper(ins.quad[1])
    output.append('push hl')
    return output


def _param32(ins):
    ''' Pushes 32bit param into the stack
    '''
    output = _32bit_oper(ins.quad[1])
    output.append('push de')
    output.append('push hl')
    return output


def _paramf16(ins):
    ''' Pushes 32bit fixed point param into the stack
    '''
    output = _f16_oper(ins.quad[1])
    output.append('push de')
    output.append('push hl')
    return output


def _paramf(ins):
    ''' Pushes 40bit (float) param into the stack
    '''
    output = _float_oper(ins.quad[1])
    output.extend(_fpush())
    return output


def _paramstr(ins):
    ''' Pushes an 16 bit unsigned value, which points
    to a string. For indirect values, it will push
    the pointer to the pointer :-)
    '''
    (tmp, output) = _str_oper(ins.quad[1])
    output.pop() # Remove a register flag (useless here)
    tmp = ins.quad[1][0] in ('#', '_') # Determine if the string must be duplicated

    if tmp:
        output.append('call __LOADSTR') # Must be duplicated
        REQUIRES.add('loadstr.asm')

    output.append('push hl')
    return output
    

def _fparam8(ins):
    ''' Passes a byte as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate)
    '''
    return _8bit_oper(ins.quad[1])


def _fparam16(ins):
    ''' Passes a word as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate)
    '''
    return _16bit_oper(ins.quad[1])


def _fparam32(ins):
    ''' Passes a dword as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate)
    '''
    return _32bit_oper(ins.quad[1])


def _fparamf16(ins):
    ''' Passes a 16.16 fixed point as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate)
    '''
    return _f16_oper(ins.quad[1])


def _fparamf(ins):
    ''' Passes a floating point as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate)
    '''
    return _float_oper(ins.quad[1])


def _fparamstr(ins):
    ''' Passes a string ptr as a __FASTCALL__ parameter.
    This is done by popping out of the stack for a
    value, or by loading it from memory (indirect)
    or directly (immediate) --prefixed with '#'--
    '''
    (tmp1, output) = _str_oper(ins.quad[1])

    return output


def _memcopy(ins):
    ''' Copies a block of memory from param 2 addr
    to param 1 addr.
    '''
    output = _16bit_oper(ins.quad[3])
    output.append('ld b, h')
    output.append('ld c, l')
    output.extend(_16bit_oper(ins.quad[1], ins.quad[2], reversed = True))
    output.append('ldir') #***

    return output


def _inline(ins):
    ''' Inline code
    '''
    tmp = [x.strip(' \t\r\n') for x in ins.quad[1].split('\n')] # Split lines

    i = 0
    while i < len(tmp):
        if not tmp[i] or tmp[i][0] == ';': # a comment or empty string?
            tmp.pop(i)
            continue

        if tmp[i][0] == '#': # A preprocessor directive
            i += 1
            continue

        match = RE_LABEL.match(tmp[i])
        if not match:
            tmp[i] = '\t' + tmp[i]
            i += 1
            continue

        if len(tmp[i][-1]) == ':':
            i += 1
            continue # This is already a single label

        tmp[i] = tmp[i][match.end() + 1:].strip(' \n')
        tmp.insert(i, match.group())
        i += 1

    output = []
    if not tmp:
        return output

    ASMLABEL = new_ASMID()
    ASMS[ASMLABEL] = tmp
    output.append('#line %s' % ins.quad[2])
    output.append(ASMLABEL)
    output.append('#line %i' % (int(ins.quad[2]) + len(tmp)))

    return output


# -------- 3 address code implementation ----------

class Quad(object):
    ''' Implements a Quad code instruction.
    '''
    def __init__(self, *args):
        ''' Creates a quad-uple checking it has the current params.
            Operatos should be passed as Quad('+', tSymbol, val1, val2)
        '''
        if not args:
            raise InvalidIC('<null>')

        if args[0] not in QUADS.keys():
            errors.throw_invalid_quad_code(args[0])

        if len(args) - 1 != QUADS[args[0]][0]:
            errors.throw_invalid_quad_params(args[0], len(args) - 1)

        args = tuple([str(x) for x in args]) # Convert it to strings

        self.quad = args
        self.op = args[0]


    def __str__(self):
        ''' String representation
        '''
        return str(self.quad)


# Table describing operations
# 'OPERATOR' -> [Number of arguments]
QUADS = {
    'addu8': [3, _add8],
    'addi8': [3, _add8],
    'addi16': [3, _add16],
    'addu16': [3, _add16],
    'addi32': [3, _add32],
    'addu32': [3, _add32],
    'addf16': [3, _addf16],
    'addf' : [3, _addf],

    'addstr': [3, _addstr],

    'subi8': [3, _sub8],
    'subu8': [3, _sub8],
    'subi16': [3, _sub16],
    'subu16': [3, _sub16],
    'subi32': [3, _sub32],
    'subu32': [3, _sub32],
    'subf16': [3, _subf16],
    'subf': [3, _subf],

    'muli8': [3, _mul8],
    'mulu8': [3, _mul8],
    'muli16': [3, _mul16],
    'mulu16': [3, _mul16],
    'muli32': [3, _mul32],
    'mulu32': [3, _mul32],
    'mulf16': [3, _mulf16],
    'mulf': [3, _mulf],

    'divu8': [3, _divu8],
    'divi8': [3, _divi8],
    'divu16': [3, _divu16],
    'divi16': [3, _divi16],
    'divu32': [3, _divu32],
    'divi32': [3, _divi32],
    'divf16': [3, _divf16],
    'divf': [3, _divf],

    'powf': [3, _powf],

    'modu8': [3, _modu8],
    'modi8': [3, _modi8],
    'modu16': [3, _modu16],
    'modi16': [3, _modi16],
    'modu32': [3, _modu32],
    'modi32': [3, _modi32],
    'modf16': [3, _modf16],
    'modf': [3, _modf],

    'shru8': [3, _shru8],
    'shri8': [3, _shri8],
    'shlu8': [3, _shl8],
    'shli8': [3, _shl8],

    'shru16': [3, _shru16],
    'shri16': [3, _shri16],
    'shlu16': [3, _shl16],
    'shli16': [3, _shl16],

    'shru32': [3, _shru32],
    'shri32': [3, _shri32],
    'shlu32': [3, _shl32],
    'shli32': [3, _shl32],

    'ltu8': [3, _ltu8],
    'lti8': [3, _lti8],
    'ltu16': [3, _ltu16],
    'lti16': [3, _lti16],
    'ltu32': [3, _ltu32],
    'lti32': [3, _lti32],
    'ltf16': [3, _ltf16],
    'ltf': [3, _ltf],
    'ltstr': [3, _ltstr],

    'gtu8': [3, _gtu8],
    'gti8': [3, _gti8],
    'gtu16': [3, _gtu16],
    'gti16': [3, _gti16],
    'gtu32': [3, _gtu32],
    'gti32': [3, _gti32],
    'gtf16': [3, _gtf16],
    'gtf': [3, _gtf],
    'gtstr': [3, _gtstr],

    'leu8': [3, _leu8],
    'lei8': [3, _lei8],
    'leu16': [3, _leu16],
    'lei16': [3, _lei16],
    'leu32': [3, _leu32],
    'lei32': [3, _lei32],
    'lef16': [3, _lef16],
    'lef': [3, _lef],
    'lestr': [3, _lestr],

    'geu8': [3, _geu8],
    'gei8': [3, _gei8],
    'geu16': [3, _geu16],
    'gei16': [3, _gei16],
    'geu32': [3, _geu32],
    'gei32': [3, _gei32],
    'gef16': [3, _gef16],
    'gef': [3, _gef],
    'gestr': [3, _gestr],

    'equ8': [3, _eq8],
    'eqi8': [3, _eq8],
    'equ16': [3, _eq16],
    'eqi16': [3, _eq16],
    'equ32': [3, _eq32],
    'eqi32': [3, _eq32],
    'eqf16': [3, _eqf16],
    'eqf': [3, _eqf],
    'eqstr': [3, _eqstr],

    'neu8': [3, _ne8],
    'nei8': [3, _ne8],
    'neu16': [3, _ne16],
    'nei16': [3, _ne16],
    'neu32': [3, _ne32],
    'nei32': [3, _ne32],
    'nef16': [3, _nef16],
    'nef': [3, _nef],
    'nestr': [3, _nestr],

    'absi8': [2, _abs8], # x = -x if x < 0
    'absi16': [2, _abs16], # x = -x if x < 0
    'absi32': [2, _abs32], # x = -x if x < 0
    'absf16': [2, _absf16], # x = -x if x < 0
    'absf': [2, _absf], # x = -x if x < 0

    'negu8': [2, _neg8],  # x = -y
    'negi8': [2, _neg8],  # x = -y
    'negu16': [2, _neg16],  # x = -y
    'negi16': [2, _neg16],  # x = -y
    'negu32': [2, _neg32],  # x = -y
    'negi32': [2, _neg32],  # x = -y
    'negf16': [2, _negf16],  # x = -y
    'negf': [2, _negf], # x = -y

    'andu8': [3, _and8],  # x = A and B
    'andi8': [3, _and8],  # x = A and B
    'andu16': [3, _and16],  # x = A and B
    'andi16': [3, _and16],  # x = A and B
    'andu32': [3, _and32],  # x = A and B
    'andi32': [3, _and32],  # x = A and B
    'andf16': [3, _andf16],  # x = A and B
    'andf': [3, _andf], # x = A and B

    'oru8': [3, _or8],  # x = A or B
    'ori8': [3, _or8],  # x = A or B
    'oru16': [3, _or16],  # x = A or B
    'ori16': [3, _or16],  # x = A or B
    'oru32': [3, _or32],  # x = A or B
    'ori32': [3, _or32],  # x = A or B
    'orf16': [3, _orf16],  # x = A or B
    'orf': [3, _orf], # x = A or B

    'xoru8': [3, _xor8],  # x = A xor B
    'xori8': [3, _xor8],  # x = A xor B
    'xoru16': [3, _xor16],  # x = A xor B
    'xori16': [3, _xor16],  # x = A xor B
    'xoru32': [3, _xor32],  # x = A xor B
    'xori32': [3, _xor32],  # x = A xor B
    'xorf16': [3, _xorf16],  # x = A xor B
    'xorf': [3, _xorf], # x = A xor B

    'notu8': [2, _not8],  # x = not B
    'noti8': [2, _not8],  # x = not B
    'notu16': [2, _not16],  # x = not B
    'noti16': [2, _not16],  # x = not B
    'notu32': [2, _not32],  # x = not B
    'noti32': [2, _not32],  # x = not B
    'notf16': [2, _notf16],  # x = not B
    'notf': [2, _notf], # x = not B

    'jump': [1, _jump],  # jmp LABEL

    'lenstr': [2, _lenstr], # Gets strlen

    'jzeroi8': [2, _jzero8],  # if X == 0 jmp LABEL
    'jzerou8': [2, _jzero8],  # if X == 0 jmp LABEL
    'jzeroi16': [2, _jzero16],  # if X == 0 jmp LABEL
    'jzerou16': [2, _jzero16],  # if X == 0 jmp LABEL
    'jzeroi32': [2, _jzero32],  # if X == 0 jmp LABEL (32bit, fixed)
    'jzerou32': [2, _jzero32],  # if X == 0 jmp LABEL (32bit, fixed)
    'jzerof16': [2, _jzerof16],  # if X == 0 jmp LABEL (32bit, fixed)
    'jzerof': [2, _jzerof],  # if X == 0 jmp LABEL (float)
    'jzerostr': [2, _jzerostr], # if str is NULL or len(str) == 0, jmp LABEL

    'jnzeroi8': [2, _jnzero8],  # if X != 0 jmp LABEL
    'jnzerou8': [2, _jnzero8],  # if X != 0 jmp LABEL
    'jnzeroi16': [2, _jnzero16],  # if X != 0 jmp LABEL
    'jnzerou16': [2, _jnzero16],  # if X != 0 jmp LABEL
    'jnzeroi32': [2, _jnzero32],  # if X != 0 jmp LABEL (32bit, fixed)
    'jnzerou32': [2, _jnzero32],  # if X != 0 jmp LABEL (32bit, fixed)
    'jnzerof16': [2, _jnzerof16],  # if X != 0 jmp LABEL (32bit, fixed)
    'jnzerof': [2, _jnzerof],  # if X != 0 jmp LABEL (float)
    'jnzerostr': [2, _jnzerostr], # if str is not NULL and len(str) > 0, jmp LABEL

    'jgezeroi8': [2, _jgezeroi8],  # if X >= 0 jmp LABEL
    'jgezerou8': [2, _jgezerou8],  # if X >= 0 jmp LABEL (ALWAYS TRUE)
    'jgezeroi16': [2, _jgezeroi16],  # if X >= 0 jmp LABEL
    'jgezerou16': [2, _jgezerou16],  # if X >= 0 jmp LABEL (ALWAYS TRUE)
    'jgezeroi32': [2, _jgezeroi32],  # if X >= 0 jmp LABEL (32bit, fixed)
    'jgezerou32': [2, _jgezerou32],  # if X >= 0 jmp LABEL (32bit, fixed) (always true)
    'jgezerof16': [2, _jgezerof16],  # if X >= 0 jmp LABEL (32bit, fixed)
    'jgezerof': [2, _jgezerof],  # if X >= 0 jmp LABEL (float)

    'paramu8': [1, _param8], # Push 8 bit param onto the stack
    'parami8': [1, _param8], # Push 8 bit param onto the stack
    'paramu16': [1, _param16], # Push 16 bit param onto the stack
    'parami16': [1, _param16], # Push 16 bit param onto the stack
    'paramu32': [1, _param32], # Push 32 bit param onto the stack
    'parami32': [1, _param32], # Push 32 bit param onto the stack
    'paramf16': [1, _paramf16], # Push 32 bit param onto the stack
    'paramf' : [1, _paramf], # Push float param - 6 BYTES (always even) onto the stack
    'paramstr' : [1, _paramstr], # Push float param - 6 BYTES (always even) onto the stack

    'fparamu8': [1, _fparam8], # __FASTCALL__ parameter
    'fparami8': [1, _fparam8], # __FASTCALL__ parameter
    'fparamu16': [1, _fparam16], # __FASTCALL__ parameter
    'fparami16': [1, _fparam16], # __FASTCALL__ parameter
    'fparamu32': [1, _fparam32], # __FASTCALL__ parameter
    'fparami32': [1, _fparam32], # __FASTCALL__ parameter
    'fparamf16': [1, _fparamf16], # __FASTCALL__ parameter
    'fparamf': [1, _fparamf], # __FASTCALL__ parameter
    'fparamstr': [1, _fparamstr], # __FASTCALL__ parameter

    'call': [2, _call], # Call Address, NNNN --- NNNN = Size (in bytes) of the returned value (0 for procedure)

    'ret' : [1, _ret], # Returns from a function call (enters the 'leave' sequence'), returning no value
    'reti8' : [2, _ret8], # Returns from a function call (enters the 'leave' sequence'), returning 8 bit value
    'retu8' : [2, _ret8], # Returns from a function call (enters the 'leave' sequence'), returning 8 bit value
    'reti16' : [2, _ret16], # Returns from a function call (enters the 'leave' sequence'), returning 16 bit value
    'retu16' : [2, _ret16], # Returns from a function call (enters the 'leave' sequence'), returning 16 bit value
    'reti32' : [2, _ret32], # Returns from a function call (enters the 'leave' sequence'), returning 32 bit value
    'retu32' : [2, _ret32], # Returns from a function call (enters the 'leave' sequence'), returning 32 bit value
    'retf16' : [2, _retf16], # Returns from a function call (enters the 'leave' sequence'), returning fixed point
    'retf' : [2, _retf], # Returns from a function call (enters the 'leave' sequence'), returning fixed point
    'retstr' : [2, _retstr], # Returns from a function call (enters the 'leave' sequence'), returning fixed point

    'leave': [1, _leave], # LEAVE label, NN -> NN = Size of parameters in bytes (End of function <label>)
    'enter': [1, _enter], # ENTER procedure/function; NN = size of local variables in bytes (Function beginning)

    'org' : [1, _org], # Defines code location
    'end' : [1, _end], # Defines an end sequence
    'label': [1, _label], # Defines a label # Flow control instructions
    'deflabel':[2, _deflabel], # Defines a label with a value

    'out' :[2, _out], # Defines a OUT instruction OUT x, y
    'in': [1, _in], # Defines an IN instruction IN x, y

    'inline': [2, _inline], # Defines an inline asm instruction

    'cast': [4, _cast], # TYPECAST: X = cast(from Type1, to Type2, Y) Ej. Converts Y 16bit to X 8bit: (cast, x, u16, u8, y)

    'storei8': [2, _store8], # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'storeu8': [2, _store8], # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'storei16': [2, _store16], # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'storeu16': [2, _store16], # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'storei32': [2, _store32], # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'storeu32': [2, _store32], # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'storef16': [2, _storef16], # STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'storef':[2, _storef],
    'storestr':[2, _storestr], # STORE STR1 <-- STR2 : Store string: Reallocs STR1 and then copies STR2 into STR1

    'astorei8': [2, _astore8], # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'astoreu8': [2, _astore8], # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'astorei16': [2, _astore16], # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'astoreu16': [2, _astore16], # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'astorei32': [2, _astore32], # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'astoreu32': [2, _astore32], # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'astoref16': [2, _astoref16], # ARRAY STORE nnnn, X  -> Stores X at position N (Type of X determines X size)
    'astoref':[2, _astoref],
    'astorestr':[2, _astorestr], # ARRAY STORE STR1 <-- STR2 : Store string: Reallocs STR1 and then copies STR2 into STR1

    'loadi8': [2, _load8], # LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
    'loadu8': [2, _load8], # LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
    'loadi16': [2, _load16], # LOAD X, nnnn  -> Load memory content at nnnn into X
    'loadu16': [2, _load16], # LOAD X, nnnn  -> Load memory content at nnnn into X
    'loadi32': [2, _load32], # LOAD X, nnnn  -> Load memory content at nnnn into X
    'loadu32': [2, _load32], # LOAD X, nnnn  -> Load memory content at nnnn into X
    'loadf16': [2, _loadf16], # LOAD X, nnnn  -> Load memory content at nnnn into X
    'loadf':[2, _loadf], # LOAD X, nnnn  -> Load memory content at nnnn into X
    'loadstr': [2, _loadstr], # LOAD X, nnnn -> Load string value at nnnn into X

    'aloadi8': [2, _aload8], # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
    'aloadu8': [2, _aload8], # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X (X must be a temporal)
    'aloadi16': [2, _aload16], # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    'aloadu16': [2, _aload16], # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    'aloadi32': [2, _aload32], # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    'aloadu32': [2, _aload32], # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    'aloadf16': [2, _aload32], # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    'aloadf':[2, _aloadf], # ARRAY LOAD X, nnnn  -> Load memory content at nnnn into X
    'aloadstr': [2, _aloadstr], # ARRAY LOAD X, nnnn -> Load string value at nnnn into X

    'pstorei8': [2, _pstore8], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pstoreu8': [2, _pstore8], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pstorei16': [2, _pstore16], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pstoreu16': [2, _pstore16], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pstorei32': [2, _pstore32], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pstoreu32': [2, _pstore32], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pstoref16': [2, _pstoref16], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pstoref':[2, _pstoref], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pstorestr':[2, _pstorestr], # STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)

    'pastorei8': [2, _pastore8], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pastoreu8': [2, _pastore8], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pastorei16': [2, _pastore16], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pastoreu16': [2, _pastore16], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pastorei32': [2, _pastore32], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pastoreu32': [2, _pastore32], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pastoref16': [2, _pastoref16], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pastoref':[2, _pastoref], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)
    'pastorestr':[2, _pastorestr], # PARAM ARRAY STORE I, nnnn, X  -> Stores X at position N (Type of X determines X size)

    'ploadi8': [2, _pload8], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'ploadu8': [2, _pload8], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'ploadi16': [2, _pload16], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'ploadu16': [2, _pload16], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'ploadi32': [2, _pload32], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'ploadu32': [2, _pload32], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'ploadf16': [2, _pload32], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'ploadf':[2, _ploadf], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'ploadstr': [2, _ploadstr], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X

    'paddr':[2, _paddr], # LOADS IX + nnnn into the stack
    'aaddr':[2, _aaddr], # LOADS ADDRESS of global ARRAY element into the stack
    'paaddr':[2, _paaddr], # LOADS ADDRESS of local ARRAY element into the stack

    'paloadi8': [2, _paload8], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'paloadu8': [2, _paload8], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'paloadi16': [2, _paload16], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'paloadu16': [2, _paload16], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'paloadi32': [2, _paload32], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'paloadu32': [2, _paload32], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'paloadf16': [2, _paload32], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'paloadf':[2, _paloadf], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X
    'paloadstr': [2, _paloadstr], # PARAM ARRAY LOAD X, nnnn  -> Load memory content at nnnn into SP + X

    'fploadstr': [2, _fploadstr], # LOAD X, nnnn  -> Load memory content at nnnn into SP + X

    'exchg' : [0, _exchg], # Exchange registers
    'nop': [0, _nop], # Used to remove (overwrite) instructions during the opt. phase
    'var': [2, _var], # Declares a variable space (filled with zeroes)
    'varx': [3, _varx], # Like the above but with a list of items (chars, bytes or words, hex)
    'vard': [2, _vard], # Like the above but with a list of items (chars, bytes or words, hex)
    'lvarx': [3, _lvarx], # Initializes a local variable. lvard X, (list of bytes): Initializes variable at offset X
    'lvard': [2, _lvard], # Initializes a local variable. lvard X, (list of bytes): Initializes variable at offset X

    'memcopy':[3, _memcopy], # Copies a block of param 3 bytes of memory from param 2 addr to param 1 addr.

    'bandu8': [3, _band8], # x = A & B
    'bandi8': [3, _band8], # x = A & B
    'boru8': [3, _bor8], # x = A | B
    'bori8': [3, _bor8], # x = A | B
    'bxoru8': [3, _bxor8], # x = A ^ B
    'bxori8': [3, _bxor8], # x = A ^ B
    'bnoti8': [2, _bnot8], # x = !A 
    'bnotu8': [2, _bnot8], # x = !A

    'bandu16': [3, _band16], # x = A & B
    'bandi16': [3, _band16], # x = A & B
    'boru16': [3, _bor16], # x = A | B
    'bori16': [3, _bor16], # x = A | B
    'bxoru16': [3, _bxor16], # x = A ^ B
    'bxori16': [3, _bxor16], # x = A ^ B
    'bnotu16': [2, _bnot16], # x = A ^ B
    'bnoti16': [2, _bnot16], # x = A ^ B

    'bandu32': [3, _band32], # x = A & B
    'bandi32': [3, _band32], # x = A & B
    'boru32': [3, _bor32], # x = A | B
    'bori32': [3, _bor32], # x = A | B
    'bxoru32': [3, _bxor32], # x = A ^ B
    'bxori32': [3, _bxor32], # x = A ^ B
    'bnotu32': [2, _bnot32], # x = A ^ B
    'bnoti32': [2, _bnot32], # x = A ^ B
}


# -------------------------
# Program Start routine
# -------------------------
def emmit_start():
    output = []

    output.append('org %s' % OPTIONS.org.value)

    if REQUIRES.intersection(MEMINITS) or '__MEM_INIT' in INITS:
        output.append('; Defines HEAP SIZE\n' + OPTIONS.heap_size_label.value + ' EQU ' + str(OPTIONS.heap_size.value))

    output.append('%s:' % START_LABEL)
    output.append('di')
    output.append('push ix')
    output.append('push iy')
    output.append('exx')
    output.append('push hl')
    output.append('exx')
    output.append('ld hl, 0')
    output.append('add hl, sp')
    output.append('ld (%s), hl' % CALL_BACK)
    output.append('ei')

    for x in sorted(INITS):
        output.append('call %s' % x)

    return output


def convertToBool():
    ''' Convert a byte value to boolean (0 or 1) if
    the global flag strictBool is True
    '''
    if not OPTIONS.strictBool.value:
        return []
    
    REQUIRES.add('strictbool.asm')

    result = []
    result.append('pop af')
    result.append('call __NORMALIZE_BOOLEAN')
    result.append('push af')

    return result


def emmit_end(MEMORY = None):
    ''' This special ending autoinitializes required inits
    (mainly alloc.asm) and changes the MEMORY initial address if it is
    ORG XXXX to ORG XXXX + heap size
    '''
    output = []
    output.extend(AT_END)

    if REQUIRES.intersection(MEMINITS) or '__MEM_INIT' in INITS:
        output.append(OPTIONS.heap_start_label.value + ':')
        output.append('; Defines DATA END\n' + 'ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP + ZXBASIC_HEAP_SIZE')
    else:
        output.append('; Defines DATA END --> HEAP size is 0\n' + 'ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP')

    output.append('; Defines USER DATA Length in bytes\n' +
        'ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA')

    if FLAG_autostart:
        output.append('END %s' % START_LABEL)
    else:
        output.append('END')

    return output


''' ---------------------------------------------
    Final (asm) instruction emission
    ---------------------------------------------
'''
def optiblock(block):
    changed = OPTIONS.optimization.value > 1
    was_changed = False

    while changed and len(block) > 1:
        changed = False

        for i in range(1, len(block)):
            i1 = inst(block[i - 1])
            o1 = oper(block[i - 1])
            i2 = inst(block[i])
            o2 = oper(block[i])

            if i < len(block) - 1:
                i3 = inst(block[i + 1])
                o3 = oper(block[i + 1])
            else:
                i3 = o3 = None

            if i1 == 'push' and i2 == 'pop':
                if OPT05 and o1 == o2:
                    # { push XX; pop XX } => {}
                    block.pop(i)
                    block.pop(i - 1)
                    was_changed = changed = True
                    break

                if i3 is not None:
                    if OPT06 and i3 == 'pop' and i > 2:
                        i0 = inst(block[i - 2])
                        o0 = oper(block[i - 2])
                        if i0 == 'push' and (o0[0] == 'hl' and o1[0] == 'de' or o0[0] == 'de' and o1[0] == 'hl'):
                            if o0 == o2 and o1 == o3: # { push hl; push de; pop hl; pop de } => {ex de, hl}
                                block.pop(i + 1)
                                block.pop(i)
                                block.pop(i - 1)
                                block[i - 2] = 'ex de, hl'
                                was_changed = changed = True
                                break

                    if OPT07 and i3 in ('pop', 'ld') and (o3 == o2 or o2[0][0] == o3[0][0] == 'a'):
                        # { push XX; pop YY; ld YY, ZZ} => {ld YY, ZZ}
                        # { push XX; pop YY; pop YY} => {pop YY}
                        block.pop(i)
                        block.pop(i - 1)
                        was_changed = changed = True
                        break

                    if OPT08 and set([o1[0], o2[0], o3[0]]) == set(['hl', 'de']):
                        block.pop(i)
                        block[i - 1] = 'ex de, hl'
                        was_changed = changed = True
                        break

                if OPT09 and not is_16bit_idx_register(o1[0]) and not is_16bit_idx_register(o2[0]):
                    block[i - 1] = 'ld %s, %s' % (o2[0][0], o1[0][0])
                    block[i] = 'ld %s, %s' % (o2[0][1], o1[0][1])
                    was_changed = changed = True
                    break

            if OPT10 and i1 == i2 == 'exx':
                block.pop(i)
                block.pop(i - 1)
                was_changed = changed = True
                break

            if OPT11 and i1 == i2 == 'ex' and o1 == o2:
                # { ex XX, YY ; ex XX, YY } => {}
                block.pop(i)
                block.pop(i - 1)
                was_changed = changed = True
                break

            if OPT12 and i1 == i2 == 'ld':
                if o1[0] == o2[0]: # LD X, Y; LD X, Z => LD X, Z
                    was_changed = changed = True
                    block.pop(i - 1)
                    break

            if OPT13 and i2 == 'ld':
                if o2[0] == o2[1]: # { LD X, X } => {}
                    was_changed = changed = True
                    block.pop(i)
                    break

            if OPT14 and i3 == i1 == 'ld' and o3[0] == o1[1] and o3[1] == o1[0] and o1[0] == 'a' and o1[1][0] == '(':
                # This is an LD a, (XX) : <inst> : Ld (XX), a
                if i2 in ('inc', 'dec') and o2[0] == 'a': # Ok, <inst> == inc/dec a
                    block.pop(i + 1)
                    block[i] = '%s (hl)' % i2
                    block[i - 1] = 'ld hl, %s' % o1[1][1:-1]
                    was_changed = changed = True
                    break

            if OPT15 and i2 == 'pop' and i1 not in ('push', 'pop'):
                if i1 != 'ex' and (o1[0] == o2[0] or len(o1[0]) == 1 and o1[0] == o2[0][0]):
                    # { ld XX, YY ; pop XX } => { pop XX }
                    was_changed = changed = True
                    block.pop(i - 1)
                    break

                if o2[0] not in o1 and o2[0][0] not in ''.join(o1) and o2[0][1] not in ''.join(o1) and 'sp' not in o1:
                    # Raises up pop un position: { inst XX ; pop YY } = { pop YY ; inst XX }
                    tmp = block[i - 1]
                    block[i - 1] = block[i]
                    block[i] = tmp
                    was_changed = changed = True
                    break

    return (was_changed, block)



def emmit(mem):
    """ Begin converting each quad instruction to asm
    by iterating over the "mem" array, and called its
    associated function. Each function returns an array of
    ASM instructions which will be appended to the
    'output' array
    """

    def output_join(output, new_chunk):
        """ Extends output instruction list
        performing a little peep-hole optimization
        """
        changed = True and OPTIONS.optimization.value > 0  # Only enter here if -O0 was not set

        while changed and len(new_chunk) > 0 and len(output) > 0:
            a1 = output[-1]      # Last output instruction
            a2 = new_chunk[0]    # Fist new output instruction

            i1 = inst(a1)
            i2 = inst(a2)
            o1 = oper(a1)
            o2 = oper(a2)

            if OPT00 and i2[-1] == ':':
                # Ok, a2 is a label
                # check if the above starts with jr / jp
                if i1 in ('jp', 'jr') and o1[0] == i2[:-1]:
                    # Ok remove the above instruction
                    output.pop()
                    changed = True
                    continue

            if OPT01 and i1 == 'push' and i2 == 'pop' and o1[0] == o2[0]:
                # Ok, we have a push/pop sequence which refers to
                # the same register pairs
                # Ok, remove these instructions (both)
                output.pop()
                new_chunk = new_chunk[1:]
                changed = True
                continue

            if OPT02 and i1 == i2 == 'ld' and o1[0] == o2[1] and o2[0] == o1[1]:
                # This and previous instruction are LD X, Y
                # Ok, previous instruction is LD A, B and current is LD B, A. Remove this one.
                new_chunk = new_chunk[1:]
                changed = True
                continue

            if OPT03 and (i1 == 'sbc' and o1[0] == o1[1] == 'a' and \
              i2 == 'or' and o2[0] == 'a' and len(new_chunk) > 1):
                a3 = new_chunk[1]
                i3 = inst(a3)
                o3 = oper(a3)
                c = condition(a3)
                if i3 in ('jp', 'jr') and c in ('z', 'nz'):
                    c = 'nc' if c == 'z' else 'c'
                    changed = True
                    output.pop()
                    new_chunk.pop(0)
                    new_chunk[0] = '%s %s, %s' % (i3, c, o3[0])
                    continue

            if OPT04 and i1 == 'push' and i2 == 'pop':
                if 'af' in (o1[0], o2[0]):
                    output.pop()
                    new_chunk[0] = 'ld %s, %s' % (o2[0][0], o1[0][0])
                    changed = True
                    continue

                if o1[0] in ('hl', 'de') and o2[0] in ('hl', 'de'):
                    # push hl; push de; pop hl; pop de || push de; push hl; pop de; pop hl => ex de, hl
                    if len(new_chunk) > 1 and len(output) > 1 and \
                        oper(new_chunk[1])[0] == o1[0] and o2[0] == oper(output[-2])[0] and \
                             inst(output[-2]) == 'push' and inst(new_chunk[1]) == 'pop':
                        output.pop()
                        new_chunk.pop(0)
                        new_chunk.pop(0)
                        output[-1] = 'ex de, hl'
                        changed = True
                        continue

                    # push hl; pop de || push de ; pop hl
                    if len(new_chunk) > 1 and inst(new_chunk[1]) in ('pop', 'ld') and oper(new_chunk[1])[0] == o1[0]:
                        output.pop()
                        new_chunk[0] = 'ex de, hl' 
                        changed = True
                        continue

                if o1[0] not in ('ix', 'iy') and o2[0] not in ('ix', 'iy'):
                    # Change push XX, pop YY sequence with ld Yh, Xl; ld Yl, Xl
                    output.pop()
                    new_chunk = ['ld %s, %s' % (o2[0][0], o1[0][0])] + new_chunk
                    new_chunk[1] = 'ld %s, %s' % (o2[0][1], o1[0][1])
                    changed = True
                    continue

            # ex af, af'; ex af, af' => <nothing>
            # ex de, hl ; ex de, hl  => <nothing>
            if OPT16 and i1 == i2 == 'ex' and o1 == o2: 
                output.pop()
                new_chunk.pop(0)
                changed = True
                continue

            if OPT17 and len(output) > 1:
                a0 = output[-2]
                i0 = inst(a0)
                o0 = oper(a0)
                if i0 == i1 == 'jp' \
                        and i2[-1] == ':' \
                        and condition(a0) is not None \
                        and condition(a1) is None \
                        and a2[:-1] in o0:
                    output.pop()
                    output.pop()
                    new_chunk = ['jp %s, %s' % ({'c': 'nc',
                                                'z': 'nz',
                                                'nc': 'c',
                                                'nz': 'z'}[condition(a0)], o1[0])] + \
                                new_chunk
                    changed = True
                    continue

            changed, new_chunk = optiblock(new_chunk)

        output.extend(new_chunk)

    output = []

    for i in mem:
        output_join(output, QUADS[i.quad[0]][1](i))
        if RE_BOOL.match(i.quad[0]):  # If it is a boolean operation convert the result to 0/1 if the STRICT_BOOL flag is True
            output_join(output, convertToBool())

    changed = OPTIONS.optimization.value > 1
    while changed:
        to_remove = []

        for i, ins in enumerate(output):
            ins = ins[:-1]
            if ins not in TMP_LABELS:
                continue

            for j, ins2 in enumerate(output):
                if j == i:
                    continue
                if ins in oper(ins2):
                    break
            else:
                to_remove.append(i)

        changed = len(to_remove) > 0
        to_remove.reverse()
        for i in to_remove:
            output.pop(i)

        tmp = output
        output = []
        for i in tmp:
            output_join(output, [i])

    i = 0
    while i < len(output):
        tmp = ASMS.get(output[i], None)
        if tmp is not None:
            output = output[:i] + tmp + output[i + 1:]
            i = 0
        else:
            i += 1

    for i in sorted(REQUIRES):
        output.append('#include once <%s>' % i)

    return output  # Caller will save its contents to a file, or whatever
