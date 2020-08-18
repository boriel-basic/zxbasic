# -*- coding: utf-8 -*-

import re

from . import patterns
from . import common

# All 'single' registers (even f FLAG one). SP is not decomposable so it's 'single' already
ALL_REGS = {'a', 'b', 'c', 'd', 'e', 'f', 'h', 'l',
            'ixh', 'ixl', 'iyh', 'iyl', 'r', 'i', 'sp'}

# The set of all registers as they can appear in any instruction as operands
REGS_OPER_SET = {'a', 'b', 'c', 'd', 'e', 'h', 'l',
                 'bc', 'de', 'hl', 'sp', 'ix', 'iy', 'ixh', 'ixl', 'iyh', 'iyl',
                 'af', "af'", 'i', 'r'}

# Instructions that marks the end of a basic block (any branching instruction)
BLOCK_ENDERS = {'jr', 'jp', 'call', 'ret', 'reti', 'retn', 'djnz', 'rst'}

UNKNOWN_PREFIX = '*UNKNOWN_'
END_PROGRAM_LABEL = '__END_PROGRAM'  # Label for end program
RE_UNK_PREFIX = re.compile('^' + re.escape(UNKNOWN_PREFIX) + r'\d+$')
HL_SEP = '|'  # Hi/Low separator


def new_tmp_val():
    """ Generates an 8-bit unknown value
    """
    common.RAND_COUNT += 1
    return '{0}{1}'.format(UNKNOWN_PREFIX, common.RAND_COUNT)


def new_tmp_val16():
    """ Generates an unknown 16-bit tmp value concatenating two 8-it unknown ones
    """
    return '{}{}{}'.format(new_tmp_val(), HL_SEP, new_tmp_val())


def is_unknown(x):
    if x is None:
        return True

    if isinstance(x, int):
        return False

    assert isinstance(x, str)
    xx = x.split(HL_SEP)
    if len(xx) > 2:
        return False

    return any(RE_UNK_PREFIX.match(_) for _ in xx)


def is_unknown8(x):
    if x is None:
        return True

    if not is_unknown(x):
        return False

    return len(x.split(HL_SEP)) == 1


def is_unknown16(x):
    if x is None:
        return True

    if not is_unknown(x):
        return False

    return len(x.split(HL_SEP)) == 2


def get_L_from_unknown_value(tmp_val):
    """ Given a 16bit *UNKNOWN value, returns it's lower part, which is the same 2nd part,
    after splitting by HL_SEP. If the parameter is None, a new tmp_value will be generated.
    If the value is a composed one (xxxH | yyyL) returns yyyL.
    """
    assert is_unknown(tmp_val), "Malformed unknown value '{}'".format(tmp_val)

    if tmp_val is None:
        tmp_val = new_tmp_val16()

    return tmp_val.split(HL_SEP)[-1]


def get_H_from_unknown_value(tmp_val):
    """ Given a 16bit *UNKNOWN value, returns it's higher part, which is the same 1st part,
    after splitting by HL_SEP. If the parameter is None, a new tmp_value will be generated.
    If the value is a composed one (xxxH | yyyL) returns yyyH.
    """
    assert is_unknown(tmp_val), "Malformed unknown value '{}'".format(tmp_val)

    if tmp_val is None:
        tmp_val = new_tmp_val16()

    return tmp_val.split(HL_SEP)[0]


def is_mem_access(arg):
    """ Returns if a given string is a memory access, that is
    if it matches the form (...)
    """
    arg = arg.strip()
    return (arg[0], arg[-1]) == ('(', ')')


# TODO: to be rewritten
def is_number(x):
    """ Returns whether X """
    if x is None or x == '':
        return False

    if isinstance(x, (int, float)):
        return True

    if isinstance(x, str):
        x = x.strip()

    if isinstance(x, str) and is_mem_access(x):
        return False

    try:
        tmp = eval(x, {}, {})
        if isinstance(tmp, (int, float)):
            return True
    except NameError:
        pass
    except SyntaxError:
        pass
    except ValueError:
        pass

    return patterns.RE_NUMBER.match(str(x)) is not None


def valnum(x):
    """ If x is a numeric value (int, float) or it's a string
    representation of a number (hexa, binary), returns it numeric value.
    Otherwise returns None
    """
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


def simplify_arg(arg):
    """ Given an asm operand (str), if it can be evaluated to a single 16 bit integer number it will be done so.
    Memory addresses will preserve their parenthesis. If the string can not be simplified, it will be
    returned as is.

    eg.:
        0       -> 0
        (0)     -> (0)
        0 + 3   -> 3
        (3 + 1) -> (4)
        (a - 1) -> (a - 1)
        b - 5   -> b - 5

    This is very simple "parsing" (for speed) and it won't understand (5) + (6) and will be returned as (11)
    """
    result = None
    arg = arg.strip()
    try:
        tmp = eval(arg, {}, {})
        if isinstance(tmp, (int, float)):
            result = str(tmp)
    except NameError:
        pass
    except SyntaxError:
        pass
    except ValueError:
        pass

    if result is None:
        return arg

    if not is_mem_access(arg):
        return result

    return '({})'.format(result)


def simplify_asm_args(asm):
    """ Given an asm instruction try to simplify its args.
    """
    chunks = [x for x in asm.split(' ', 1)]
    if len(chunks) != 2:
        return asm

    args = [simplify_arg(x) for x in chunks[1].split(',', 1)]
    return '{} {}'.format(chunks[0], ', '.join(args))


def is_register(x):
    """ True if x is a register.
    """
    if not isinstance(x, str):
        return False

    return x.lower() in REGS_OPER_SET


def is_8bit_normal_register(x):
    """ Returns whether the given string x is a "normal" 8 bit register. Those are 8 bit registers
    which belongs to the normal (documented) Z80 instruction set as operands (so a', f', ixh, etc
    are excluded).
    """
    return x.lower() in {'a', 'b', 'c', 'd', 'e', 'i', 'h', 'l'}


def is_8bit_idx_register(x):
    """ Returns whether the given string x one of the undocumented IX, IY 8 bit registers.
    """
    return x.lower() in {'ixh', 'ixl', 'iyh', 'iyl'}


def is_8bit_oper_register(x):
    """ Returns whether the given string x is an 8 bit register that can be used as an
    instruction operand. This included those of the undocumented Z80 instruction set as
    operands (ixh, ixl, etc) but not h', f'.
    """
    return x.lower() in {'a', 'b', 'c', 'd', 'e', 'i', 'h', 'l', 'ixh', 'ixl', 'iyh', 'iyl'}


def is_16bit_normal_register(x):
    """ Returns whether the given string x is a "normal" 16 bit register. Those are 16 bit registers
    which belongs to the normal (documented) Z80 instruction set as operands which can be operated
    directly (i.e. load a value directly), and not for indexation (IX + n, for example).
    So af, ix, iy, sp, bc', hl', de' are excluded.
    """
    return x.lower() in {'bc', 'de', 'hl'}


def is_16bit_idx_register(x):
    """ Returns whether the given string x is a indexable (i.e. IX + n) 16 bit register.
    """
    return x.lower() in {'ix', 'iy'}


def is_16bit_composed_register(x):
    """ A 16bit register that can be decomposed into a high H16 and low L16 part
    """
    return x.lower() in {'af', "af'", 'bc', 'de', 'hl', 'ix', 'iy'}


def is_16bit_oper_register(x):
    """ Returns whether the given string x is a 16 bit register. These are any 16 bit register
    which belongs to the normal (documented) Z80 instruction set as operands.
    """
    return x.lower() in {'af', "af'", 'bc', 'de', 'hl', 'ix', 'iy', 'sp'}


def LO16(x):
    """ Given a 16-bit register (lowercase string), returns the low 8 bit register of it.
    The string *must* be a 16 bit lowercase register. SP register is not "decomposable" as
    two 8-bit registers and this is considered an error.
    """
    x = x.lower()
    assert is_16bit_oper_register(x), "'%s' is not a 16bit register" % x
    assert x != 'sp', "'sp' register cannot be split into two 8 bit registers"

    if is_16bit_idx_register(x):
        return x + 'l'

    return x[1] + ("'" if "'" in x else '')


def HI16(x):
    """ Given a 16-bit register (lowercase string), returns the high 8 bit register of it.
    The string *must* be a 16 bit lowercase register. SP register is not "decomposable" as
    two 8-bit registers and this is considered an error.
    """
    x = x.lower()
    assert is_16bit_oper_register(x), "'%s' is not a 16bit register" % x
    assert x != 'sp', "'sp' register cannot be split into two 8 bit registers"

    if is_16bit_idx_register(x):
        return x + 'h'

    return x[0] + ("'" if "'" in x else '')


def single_registers(op):
    """ Given an iterable (set, list) of registers like ['a', 'bc', "af'", 'h', 'hl'] returns
    a list of single registers: ['a', "a'", "f'", 'b', 'c', 'h', 'l'].
    Non register parameters (like numbers) will be ignored.

    Notes:
        - SP register will be returned as is since it's not decomposable in two 8 bit registers.
        - IX and IY will be returned as {'ixh', 'ixl'} and {'iyh', 'iyl'} respectively
    """
    result = set()
    if not isinstance(op, (list, set)):
        op = [op]

    for x in op:
        if is_8bit_oper_register(x) or x.lower() in ('f', 'sp'):
            result.add(x)
        elif not is_16bit_oper_register(x):
            continue
        else:  # Must be a 16bit reg or we have an internal error!
            result = result.union([LO16(x), HI16(x)])

    return sorted(result)


def idx_args(x):
    """ Given an argument x (string), returns None if it's not an index operation "ix/iy + n"
    Otherwise return a tuple (reg, oper, offset). It's case insensitive and the register is always returned
    in lowercase.

    Notice the parenthesis must NOT be included. So '(ix + 5)' won't match, whilst 'ix + 5' will.

    For example:
     - 'ix + 3' => ('ix', '+', '3')
     - 'IY - Something + 4' => ('iy', '-', 'Something + 4')
    """
    match = patterns.RE_IDX.match(x)
    if match is None:
        return None

    reg, sign, args = match.groups()
    return reg.lower(), sign, args


def LO16_val(x):
    """ Given an x value, it must be None, unknown, or an integer.
    Then returns it lower part. If it's none, a new tmp will be returned.
    """
    if x is None:
        return new_tmp_val()

    if valnum(x) is not None:
        return str(int(x) & 0xFF)

    if not is_unknown(x):
        return new_tmp_val()

    return x.split(HL_SEP)[-1]


def HI16_val(x):
    """ Given an x value, it must be None, unknown, or an integer.
    Then returns it upper part. If it's None, a new tmp will be returned.
    It it's an unknown8, return 0, because it's considered an 8 bit value.
    """
    if x is None:
        return new_tmp_val()

    if valnum(x) is not None:
        return str((int(x) >> 8) & 0xFF)

    if not is_unknown(x):
        return new_tmp_val()

    return "0{}{}".format(HL_SEP, x).split(HL_SEP)[-2]


def dict_intersection(dict_a, dict_b):
    """ Given 2 dictionaries a, b, returns a new one which contains the common key/pair values.
    e.g. for {'a': 1, 'b': 'x'}, {'a': 'q', 'b': 'x', 'c': 2} returns {'b': 'x'}

    :param dict_a: a python dictionary (or compatible class instance)
    :param dict_b: a python dictionary (or compatible class instance)

    :return a python dictionary with the key/val intersection
    """
    return {k: v for k, v in dict_a.items() if k in dict_b and dict_b[k] == v}
