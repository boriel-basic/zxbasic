#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim:ts=4:sw=4:et:

# ------------------------------------------------
# Translates the AST to Quad code chunks
# ------------------------------------------------

import backend
import zxbparser
from backend import Quad, MEMORY
from zxbparser import Tree, TYPE_SIZES, optemps, is_number, is_unsigned, warning
from backend.__float import _float
from obj.errors import Error
from obj import OPTIONS
from symbol import SymbolCONST
import arch.zx48k.beep


class InvalidOperatorError(Error):
    def __init__(self, operator):
        self.msg = 'Invalid operator "%s"' % str(operator)


class InvalidLoopError(Error):
    def __init__(self, loop):
        self.msg = 'Invalid loop type error (not found?) "%s"' % str(loop)


# Optimization level as a function
def O_LEVEL():
    return OPTIONS.optimization.value

# Emmits an optimization warning
def warning_not_used(lineno, id):
    if O_LEVEL() > 0:
        warning(lineno, "Variable '%s' is never used" % id)


def dumpMemory(MEMORY):
    ''' Returns a sequence of Quads
    '''
    for x in MEMORY:
        yield str(x)


# ------------------------------------------------------
# Returns true if the passed token is an unknown string
# or a constant string having control chars (inverse, etc
# ------------------------------------------------------
def has_control_chars(i):
    if not hasattr(i, '_type'):
        return False

    if i._type != 'string':
        return False

    if i.token == 'ID':
        return True # We don't know what an alphanumeric variable will hold

    if i.text is None:
        return True

    for c in i.text:
        if ord(c) > 15 and ord(c) < 22: # is it an attr char?
            return True

    for j in i.next:
        if has_control_chars(j):
            return True

    return False



# ------------------------------------------------
# REQUIRES = set of include archives
# ------------------------------------------------
REQUIRES = backend.REQUIRES


MEMORY = [] # Memory array of output instructions

# ------------------------------------------------
# Type suffixes
# ------------------------------------------------
TSUFFIX = {'i8': 'i8', 'u8': 'u8', 'i16': 'i16', 'u16': 'u16',
            'i32': 'i32', 'u32': 'u32', 'fixed': 'f16', 'float': 'f',
            'string': 'str'
        }


# ------------------------------------------------
# A list of tokens that belongs to temporary
# ATTR setting
# ------------------------------------------------
ATTR = ('INK', 'PAPER', 'BRIGHT', 'FLASH', 'OVER', 'INVERSE', 'BOLD', 'ITALIC')
ATTR_TMP = tuple(x + '_TMP' for x in ATTR)

# Functions pending to emmit
FUNCTIONS = []

# ----------------------------------------------------------------------
# Constant strings used in the program. Duplicated strings will be
# reused.
# ----------------------------------------------------------------------
STRING_LABELS = {}

# Defined LOOPS
LOOPS = []

# Local flags
HAS_ATTR = False

# Previous Token
PREV_TOKEN = None

# Current Token
CURR_TOKEN = None


def debmsg(msg):
    if not OPTIONS.Debug.value:
        return

    print "DEBUG zxbtrad: %s" % str(msg)


def default_value(_type, value):
    ''' Returns a list of bytes (as hexadecimal 2 char string)
    '''
    if _type == 'float':
        C, DE, HL = _float(value)
        C = C[:-1] # Remove 'h' suffix
        if len(C) > 2:
            C = C[-2:]

        DE = DE[:-1] # Remove 'h' suffix
        if len(DE) > 4:
            DE = DE[-4:]
        elif len(DE) < 3:
            DE = '00' + DE

        HL = HL[:-1] # Remove 'h' suffix
        if len(HL) > 4:
            HL = HL[-4:]
        elif len(HL) < 3:
            HL = '00' + HL

        return [C, DE[-2:], DE[:-2], HL[-2:], HL[:-2]]

    if _type == 'fixed':
        value = 0xFFFFFFFF & int(value * 2**16)

    # It's an integer type
    value = int(value)
    result = [value, value >> 8, value >> 16, value >> 24]
    result = ['%02X' % (value & 0xFF) for value in result]

    return result[:TYPE_SIZES[_type]]


def array_default_value(_type, values):
    ''' Returns a list of bytes (as hexadecimal 2 char string)
    which represents the array initial value.
    '''
    if not isinstance(values, list):
        return default_value(_type, values.value)

    l = []
    for row in values:
        l.extend(array_default_value(_type, row))

    return l


def loop_exit_label(loop_type):
    ''' Returns the label for the given loop type which
    exits the loop. loop_type must be one of 'FOR', 'WHILE', 'DO'
    '''
    for i in range(len(LOOPS) - 1, -1, -1):
        if loop_type == LOOPS[i][0]:
            return LOOPS[i][1]

    raise InvalidLoopError(loop_type)


def loop_cont_label(loop_type):
    ''' Returns the label for the given loop type which
    continues the loop. loop_type must be one of 'FOR', 'WHILE', 'DO'
    '''
    for i in range(len(LOOPS) - 1, -1, -1):
        if loop_type == LOOPS[i][0]:
            return LOOPS[i][2]

    raise InvalidLoopError(loop_type)


def emmit_let_left_part(tree, t = None):
    scope = tree.next[0].symbol.scope
    p = '*' if tree.next[0].symbol.byref else '' # Indirection prefix

    if t is None:
        t = tree.next[1].t
    
    if O_LEVEL() > 1 and not tree.next[0].symbol.accessed: return

    alias = tree.next[0].symbol.alias

    if scope == 'global':
        emmit('store' + TSUFFIX[tree.next[0]._type], tree.next[0].symbol._mangled, t)
    elif scope == 'parameter':
        emmit('pstore' + TSUFFIX[tree.next[0]._type], p + str(tree.next[0].symbol.offset), t)
    elif scope == 'local':
        offset = tree.next[0].symbol.offset
        if alias is not None and alias._class == 'array':
            offset -= 1 + 2 * alias.count
        emmit('pstore' + TSUFFIX[tree.next[0]._type], p + str(-offset), t)


def emmit(*args):
    ''' Convert the given args to a Quad (3 address code) instruction
    '''
    global MEMORY

    quad = Quad(*args)
    debmsg('EMMIT ' + str(quad))

    MEMORY.append(quad)


def check_attr(tree, n):
    ''' Check if ATTR has to be normalized
    after this instruction has been translated
    to intermediate code.
    '''
    return len(tree) > n


def norm_attr():
    ''' Normalize attr state
    '''
    global HAS_ATTR

    if not HAS_ATTR:
        return

    HAS_ATTR = False
    emmit('call', 'COPY_ATTR', 0)
    REQUIRES.add('copy_attr.asm')


def traverse_const(tree):
    ''' Traverses a constant and returns an string
    with the arithmetic expression
    '''
    if tree.token == 'NUMBER':
        tree.t = str(tree.t)

    elif tree.token == 'UNARY':
        mid = tree.text
        if mid == 'MINUS':
            tree.t = ' -' + traverse_const(tree.next[0])
        elif mid == 'ADDRESS':
            tree.t = traverse_const(tree.next[0])
        else:
            raise InvalidOperatorError(mid)

    elif tree.token == 'BINARY':
        mid = tree.text
        if mid == 'PLUS':
            mid = '+'
        elif mid == 'MINUS':
            mid = '-'
        elif mid == 'MUL':
            mid = '*'
        elif mid == 'DIV':
            mid = '/'
        elif mid == 'POW':
            mid = '^'
        elif mid == 'SHL':
            mid = '>>'
        elif mid == 'SHR':
            mid = '<<'
        else:
            raise InvalidOperatorError(mid)

        tree.t = traverse_const(tree.next[0]) + ' ' + mid + ' ' + traverse_const(tree.next[1])

    elif tree.token == 'ID':
        tree.t = tree.symbol._mangled
    elif tree.token == 'CONST':
        return traverse_const(tree.expr)

    return tree.t


def traverse(tree):
    ''' Recursive function that will emmit the AST
    stored function to the MEMORY array
    '''
    global HAS_ATTR, PREV_TOKEN, CURR_TOKEN

    if tree is None:
        return

    if isinstance(tree, list):
        for l in tree:
            traverse(l)
        return

    PREV_TOKEN = CURR_TOKEN
    CURR_TOKEN = tree.token

    debmsg('AST -> ' + tree.token)

    if tree.token == 'BLOCK': # Code block?
        for i in tree.next:
            traverse(i)

    elif tree.token == 'NOP': # Do nothing
        pass

    elif tree.token == 'END': # end of code
        traverse(tree.next[0])
        emmit('end', tree.next[0].t)

    elif tree.token == 'ERROR': # Raises an error
        traverse(tree.next[0])
        emmit('fparamu8', tree.next[0].t)
        emmit('call', '__ERROR', 0)
        REQUIRES.add('error.asm')

    elif tree.token == 'STOP': # Returns to BASIC with an error code
        traverse(tree.next[0])
        emmit('fparamu8', tree.next[0].t)
        emmit('call', '__STOP', 0)
        emmit('end', 0)
        REQUIRES.add('error.asm')

    elif tree.token == 'CONST': # a CONSTant expression
        tree.t = '#' + traverse_const(tree.symbol.expr)

    elif tree.token == 'BORDER':
        traverse(tree.next[0])
        emmit('fparamu8', tree.next[0].t)
        emmit('call', 'BORDER', 0) # Procedure call. Discard return
        REQUIRES.add('border.asm')

    # INK, PAPER, ... etc
    elif tree.token in ATTR:
        traverse(tree.next[0])
        emmit('fparamu8', tree.next[0].t)
        emmit('call', tree.token, 0)
        REQUIRES.add('%s.asm' % tree.token.lower())
        HAS_ATTR = True

    elif tree.token == 'OUT':
        traverse(tree.next[0])
        traverse(tree.next[1])
        emmit('out', tree.next[0].t, tree.next[1].t)

    elif tree.token == 'PLOT':
        TMP_HAS_ATTR = check_attr(tree.next, 2)
        if TMP_HAS_ATTR:
            traverse(tree.next[2]) # Temporary attributes

        traverse(tree.next[0])
        emmit('paramu8', tree.next[0].t)
        traverse(tree.next[1])
        emmit('fparamu8', tree.next[1].t)
        emmit('call', 'PLOT', 0) # Procedure call. Discard return
        REQUIRES.add('plot.asm')
        HAS_ATTR = TMP_HAS_ATTR

    elif tree.token == 'DRAW':
        TMP_HAS_ATTR = check_attr(tree.next, 2)
        if TMP_HAS_ATTR:
            traverse(tree.next[2]) # Temporary attributes

        traverse(tree.next[0])
        emmit('parami16', tree.next[0].t)
        traverse(tree.next[1])
        emmit('fparami16', tree.next[1].t)
        emmit('call', 'DRAW', 0) # Procedure call. Discard return
        REQUIRES.add('draw.asm')
        HAS_ATTR = TMP_HAS_ATTR

    elif tree.token == 'DRAW3':
        TMP_HAS_ATTR = check_attr(tree.next, 3)
        if TMP_HAS_ATTR:
            traverse(tree.next[3]) # Temporary attributes

        traverse(tree.next[0])
        emmit('parami16', tree.next[0].t)
        traverse(tree.next[1])
        emmit('parami16', tree.next[1].t)
        traverse(tree.next[2])
        emmit('fparamf', tree.next[2].t)
        emmit('call', 'DRAW3', 0) # Procedure call. Discard return
        REQUIRES.add('draw3.asm')
        HAS_ATTR = TMP_HAS_ATTR

    elif tree.token == 'CIRCLE':
        TMP_HAS_ATTR = check_attr(tree.next, 3)
        if TMP_HAS_ATTR:
            traverse(tree.next[3]) # Temporary attributes

        traverse(tree.next[0])
        emmit('paramu8', tree.next[0].t)
        traverse(tree.next[1])
        emmit('paramu8', tree.next[1].t)
        traverse(tree.next[2])
        emmit('fparamu8', tree.next[2].t)
        emmit('call', 'CIRCLE', 0) # Procedure call. Discard return
        REQUIRES.add('circle.asm')
        HAS_ATTR = TMP_HAS_ATTR

    elif tree.token == 'BEEP':
        if tree.next[0].token == tree.next[1].token == 'NUMBER': # BEEP <const>, <const>
            DE, HL = arch.zx48k.beep.getDEHL(float(tree.next[0].t), float(tree.next[1].t))
            emmit('paramu16', HL)
            emmit('fparamu16', DE)
            emmit('call', '__BEEPER', 0) # Procedure call. Discard return
            REQUIRES.add('beeper.asm')
        else:
            traverse(tree.next[1])
            emmit('paramf', tree.next[1].t)
            traverse(tree.next[0])
            emmit('fparamf', tree.next[0].t)
            emmit('call', 'BEEP', 0) # Procedure call. Discard return
            REQUIRES.add('beep.asm')

    elif tree.token == 'CLS':
        emmit('call', 'CLS', 0)
        REQUIRES.add('cls.asm')

    elif tree.token == 'POKE':
        traverse(tree.next[0])
        traverse(tree.next[1])

        if tree.next[0].token == 'ID' and tree.next[0]._class != 'const' and tree.next[0].symbol.scope == 'global': 
            emmit('store' + TSUFFIX[tree.next[1]._type], '*' + str(tree.next[0].t), tree.next[1].t)
        else:
            emmit('store' + TSUFFIX[tree.next[1]._type], tree.next[0].t, tree.next[1].t)

    elif tree.token == 'PAUSE':
        traverse(tree.next[0])
        emmit('fparamu16', tree.next[0].t)
        emmit('call', '__PAUSE', 0)
        REQUIRES.add('pause.asm')

    elif tree.token == 'CAST':
        traverse(tree.next[0])
        emmit('cast', tree.t, tree.next[0]._type, tree._type, tree.next[0].t)

    elif tree.token == 'UNARY':
        oper = tree.text

        if oper == 'RND': # A special "ZEROARY" function with no parameters
            emmit('call', 'RND', TYPE_SIZES['float'])
            REQUIRES.add('random.asm')
            return

        if oper == 'INKEY': # A special "ZEROARY" function with no parameters
            emmit('call', 'INKEY', TYPE_SIZES['string'])
            REQUIRES.add('inkey.asm')
            return

        if oper == 'IN': # In port
            emmit('in', tree.next[0].t)
            return

        if oper == 'ADDRESS' and tree.next[0].token != 'ARRAYACCESS':
            scope = tree.next[0].symbol.scope

            # It's a scalar variable
            if scope == 'global':
                emmit('load' + TSUFFIX[tree._type], tree.t, '#' + tree.next[0].symbol._mangled)
            elif scope == 'parameter':
                emmit('paddr', tree.next[0].symbol.offset + 1 if (tree.next[0]._type in 'u8', 'i8', 'float') else 0, tree.t)
            elif scope == 'local':
                emmit('paddr', -tree.next[0].symbol.offset, tree.t)
            return

        if oper in ('LBOUND', 'UBOUND'): # LBOUND is codified as a Unary with a t-uple arg
            entry = tree.array_id
            scope = entry.scope

            if oper == 'LBOUND':
                emmit('paramu16', '#__LBOUND__.' + entry._mangled)
            else:
                emmit('paramu16', '#__UBOUND__.' + entry._mangled)

            traverse(tree.next[0])
            t = optemps.new_t()
            emmit('fparamu16', t) 
            emmit('call', '__BOUND', TYPE_SIZES['u16'])
            REQUIRES.add('bound.asm')
            return

        traverse(tree.next[0])
        si = TYPE_SIZES[tree._type]
        s = TSUFFIX[tree._type]

        if oper == 'ADDRESS': # Address of the next expression
            scope = tree.next[0].symbol.scope

            # Address of an array element.
            if scope == 'global':
                emmit('aaddr', tree.t, tree.next[0].symbol._mangled)
            elif scope == 'parameter':
                emmit('paaddr', tree.t, tree.next[0].symbol.entry.offset)
            elif scope == 'local':
                emmit('paaddr', tree.t, -tree.next[0].symbol.entry.offset)
            return


        if oper == 'MINUS':
            ins = 'neg'
            emmit(ins + s, tree.t, tree.next[0].t)
            return

        elif oper == 'NOT':
            ins = 'not'
            emmit(ins + TSUFFIX[tree.next[0]._type], tree.t, tree.next[0].t)
            return

        elif oper == 'BNOT':
            ins = 'bnot'
            emmit(ins + TSUFFIX[tree.next[0]._type], tree.t, tree.next[0].t)
            return

        elif oper == 'SIN': # TRIGONOMETRICS
            emmit('fparam' + s, tree.next[0].t)
            emmit('call', 'SIN', si)
            REQUIRES.add('sin.asm')
            return

        elif oper == 'COS': # TRIGONOMETRICS
            emmit('fparamf', tree.next[0].t)
            emmit('call', 'COS', si)
            REQUIRES.add('cos.asm')
            return

        elif oper == 'TAN': # TRIGONOMETRICS
            emmit('fparamf', tree.next[0].t)
            emmit('call', 'TAN', si)
            REQUIRES.add('tan.asm')
            return

        elif oper == 'ASN': # TRIGONOMETRICS
            emmit('fparam' + s, tree.next[0].t)
            emmit('call', 'ASIN', si)
            REQUIRES.add('asin.asm')
            return

        elif oper == 'ACS': # TRIGONOMETRICS
            emmit('fparamf', tree.next[0].t)
            emmit('call', 'ACOS', si)
            REQUIRES.add('acos.asm')
            return

        elif oper == 'ATN': # TRIGONOMETRICS
            emmit('fparamf', tree.next[0].t)
            emmit('call', 'ATAN', si)
            REQUIRES.add('atan.asm')
            return

        elif oper == 'EXP': # e^x
            emmit('fparamf', tree.next[0].t)
            emmit('call', 'EXP', si)
            REQUIRES.add('exp.asm')
            return

        elif oper == 'LN': # LogE
            emmit('fparamf', tree.next[0].t)
            emmit('call', 'LN', si)
            REQUIRES.add('logn.asm')
            return

        elif oper == 'SQR': # Square Root
            emmit('fparamf', tree.next[0].t)
            emmit('call', 'SQRT', si)
            REQUIRES.add('sqrt.asm')
            return

        elif oper == 'USR': # USR call
            emmit('fparamu16', tree.next[0].t)
            emmit('call', 'USR', si)
            REQUIRES.add('usr.asm')
            return

        elif oper == 'USR_STR': # USR ADDR
            emmit('fparamstr', tree.next[0].t)
            emmit('call', 'USR_STR', si)
            REQUIRES.add('usr_str.asm')
            return

        elif oper == 'PEEK': # Peek a value from memory
            emmit('load' + s, tree.t, '*' + str(tree.next[0].t))
            return

        elif oper == 'LEN': # STRLEN
            emmit('lenstr', tree.t, tree.next[0].t)
            return

        elif oper == 'SGN':
            _type = tree.next[0]._type
            emmit('fparam' + TSUFFIX[_type], tree.next[0].t)
            if _type == 'fixed':
                _type = 'f16'
            elif _type == 'float':
                _type = 'f'

            emmit('call', '__SGN' + _type.upper(), 1)
            REQUIRES.add('sgn%s.asm' % _type)
            return

        elif oper == 'ABS':
            _type = tree.next[0]._type
            emmit('abs' + TSUFFIX[_type], tree.t, tree.next[0].t)
            return

        elif oper == 'VAL': # VAL
            emmit('fparamu16', tree.next[0].t)

            if tree.next[0].token != 'STRING' and tree.next[0].token != 'ID' and tree.next[0].t != '_':
                emmit('fparamu8', 1) # If the argument is not a variable, it must be freed
            else:
                emmit('fparamu8', 0)

            emmit('call', 'VAL', si)
            REQUIRES.add('val.asm')
            return

        elif oper == 'CODE': # CODE
            emmit('fparamu16', tree.next[0].t)

            if tree.next[0].token != 'STRING' and tree.next[0].token != 'ID' and tree.next[0].t != '_':
                emmit('fparamu8', 1) # If the argument is not a variable, it must be freed
            else:
                emmit('fparamu8', 0)

            emmit('call', '__ASC', si)
            REQUIRES.add('asc.asm')
            return

        elif oper == 'STR':
            emmit('fparamf', tree.next[0].t)
            emmit('call', '__STR_FAST', si)
            REQUIRES.add('str.asm')
            return

        elif oper == 'CHR':
            emmit('fparamu16', tree.next[0].symbol.count) # Number of args
            emmit('call', 'CHR', si)
            REQUIRES.add('chr.asm')
            return

        else: # Invalid Oper
            raise InvalidOperatorError(oper)


    elif tree.token == 'BINARY':
        traverse(tree.next[0])
        traverse(tree.next[1])

        oper = tree.text
        s = TSUFFIX[tree.next[0]._type]

        # Switch
        if oper == 'PLUS':        # Arithmetic
            ins = 'add'
        elif oper == 'MINUS':
            ins = 'sub'
        elif oper == 'MUL':
            ins = 'mul'
        elif oper == 'DIV':
            ins = 'div'
        elif oper == 'MOD':
            ins = 'mod'
        elif oper == 'POW':
            ins = 'pow'
        elif oper == 'SHL':
            ins = 'shl'
        elif oper == 'SHR':
            ins = 'shr'

        elif oper == 'LT':        # Comparisons
            ins = 'lt'
        elif oper == 'LE':
            ins = 'le'
        elif oper == 'GT':
            ins = 'gt'
        elif oper == 'GE':
            ins = 'ge'
        elif oper == 'EQ':
            ins = 'eq'
        elif oper == 'NE':
            ins = 'ne'

        elif oper == 'AND':
            ins = 'and'
        elif oper == 'OR':
            ins = 'or'
        elif oper == 'XOR':
            ins = 'xor'

        elif oper == 'BAND':
            ins = 'band'
        elif oper == 'BOR':
            ins = 'bor'
        elif oper == 'BXOR':
            ins = 'bxor'
        else:
            raise InvalidOperatorError(oper)

        emmit(ins + s, tree.t, str(tree.next[0].t), str(tree.next[1].t))

    elif tree.token == 'ID':
        scope = tree.symbol.scope

        if tree.t == tree.symbol._mangled and scope == 'global':
            return

        if tree._class in ('label', 'const'):
            return

        suffix = TSUFFIX[tree._type]
        p = '*' if tree.symbol.byref else '' # Indirection prefix
        alias = tree.symbol.alias

        if scope == 'global':
            emmit('load' + suffix, tree.t, tree.symbol._mangled)
        elif scope == 'parameter':
            emmit('pload' + suffix, tree.t, p + str(tree.symbol.offset))
        elif scope == 'local':
            offset = tree.symbol.offset
            if alias is not None and alias._class == 'array':
                offset -= 1 + 2 * alias.count

            emmit('pload' + suffix, tree.t, p + str(-offset))

    elif tree.token == 'STRING': # String constant
        if tree.text not in STRING_LABELS.keys():
            STRING_LABELS[tree.text] = backend.tmp_label()

        tree.t = '#' + STRING_LABELS[tree.text]

    elif tree.token == 'STRSLICE': # String slicing
        traverse(tree.next[0])

        if tree.next[0].token == 'STRING' or \
           tree.next[0].token == 'ID' and tree.next[0].symbol.scope == 'global':
            emmit('paramu16', tree.next[0].t)

        # Now emmit the slicing indexes

        traverse(tree.next[1])
        emmit('param' + TSUFFIX[tree.next[1]._type], tree.next[1].t)
        traverse(tree.next[2])
        emmit('param' + TSUFFIX[tree.next[2]._type], tree.next[2].t)

        if tree.next[0].token == 'ID' and tree.next[0].symbol._mangled[0] == '_' or \
            tree.next[0].token == 'STRING':
            emmit('fparamu8', 0)
        else:
            emmit('fparamu8', 1) # If the argument is not a variable, it must be freed

        emmit('call', '__STRSLICE', 2)
        REQUIRES.add('strslice.asm')

    elif tree.token == 'VARDECL': # Global Variable declaration
        if not tree.symbol.entry.accessed:
            warning_not_used(tree.symbol.entry.lineno, tree.symbol.entry.id)
            if O_LEVEL() > 1:
                return

        if tree.symbol.entry.addr is not None:
            emmit('deflabel', tree.symbol.entry._mangled, tree.symbol.entry.addr)
            for entry in tree.symbol.entry.aliased_by:
                emmit('deflabel', entry._mangled, entry.addr)
        elif tree.symbol.entry.alias is None:
            for alias in tree.symbol.entry.aliased_by:
                emmit('label', alias._mangled)
            if tree.symbol.entry.default_value is None:
                emmit('var', tree.text, tree.symbol.size)
            else:
                if isinstance(tree.symbol.entry.default_value, SymbolCONST) and \
                 tree.symbol.entry.default_value.token == 'CONST':
                    emmit('varx', tree.text, tree._type, [traverse_const(tree.symbol.entry.default_value)])
                else:
                    emmit('vard', tree.text, default_value(tree.symbol._type, tree.symbol.entry.default_value))

    elif tree.token == 'ARRAYDECL': # Global Array Declaration
        if not tree.symbol.entry.accessed:
            warning_not_used(tree.symbol.entry.lineno, tree.symbol.entry.id)
            if O_LEVEL() > 1:
                return

        l = ['%04X' % (len(tree.symbol.bounds.next) - 1)] # Number of dimensions - 1

        for bound in tree.symbol.bounds.next[1:]:
            l.append('%04X' % (bound.symbol.upper - bound.symbol.lower + 1))

        l.append('%02X' % TYPE_SIZES[tree.symbol._type])

        if tree.symbol.entry.default_value is not None:
            l.extend(array_default_value(tree.symbol._type, tree.symbol.entry.default_value))
        else:
            l.extend(['00'] * tree.symbol.size)

        for alias in tree.symbol.entry.aliased_by:
            offset = 1 + 2 * tree.symbol.entry.count + alias.offset
            emmit('deflabel', alias._mangled, '%s + %i' % (tree.symbol.entry._mangled, offset))

        emmit('vard', tree.text, l)

        if tree.symbol.entry.lbound_used:
            l = ['%04X' % len(tree.symbol.bounds.next)] + \
                ['%04X' % bound.symbol.lower for bound in tree.symbol.bounds.next]
            emmit('vard', '__LBOUND__.' + tree.symbol.entry._mangled, l)

        if tree.symbol.entry.ubound_used:
            l = ['%04X' % len(tree.symbol.bounds.next)] + \
                ['%04X' % bound.symbol.upper for bound in tree.symbol.bounds.next]
            emmit('vard', '__UBOUND__.' + tree.symbol.entry._mangled, l)


    elif tree.token == 'ARRAYACCESS': # Access to an array Element
        traverse(tree.next[0])
        if OPTIONS.arrayCheck.value:
            upper = tree.symbol.entry.bounds.next[0].symbol.upper
            lower = tree.symbol.entry.bounds.next[0].symbol.lower
            emmit('paramu16', upper - lower)

    elif tree.token == 'ARRAYLOAD': # Access to an array Element
        scope = tree.symbol.scope
        offset = None if len(tree.next) < 2 else tree.next[1]

        if offset is None:
            traverse(tree.next[0])

            if OPTIONS.arrayCheck.value:
                upper = tree.symbol.entry.bounds.next[0].symbol.upper
                lower = tree.symbol.entry.bounds.next[0].symbol.lower
                emmit('paramu16', upper - lower)

            if scope == 'global':
                emmit('aload' + TSUFFIX[tree._type], tree.symbol.t, tree.symbol._mangled)
            elif scope == 'parameter':
                emmit('paload' + TSUFFIX[tree._type], tree.t, tree.symbol.entry.offset)
            elif scope == 'local':
                emmit('paload' + TSUFFIX[tree._type], tree.t, -tree.symbol.entry.offset)
        else:
            offset = 1 + 2 * tree.symbol.entry.count + offset.value
            if scope == 'global':
                emmit('load' + TSUFFIX[tree._type], tree.symbol.t, '%s + %i' % (tree.symbol._mangled, offset))
            elif scope == 'parameter':
                emmit('pload' + TSUFFIX[tree._type], tree.t, tree.symbol.entry.offset - offset)
            elif scope == 'local':
                emmit('pload' + TSUFFIX[tree._type], tree.t, -(tree.symbol.entry.offset - offset))

    elif tree.token == 'ARRAYCOPY':
        tr = tree.next[0]
        scope = tr.symbol.scope
        offset = 1 + 2 * tr.symbol.count
        if scope == 'global':
            #emmit('loadu16', tr.symbol.t, '#%s + %i' % (tr.symbol._mangled, offset))
            t1 = "#%s + %i" % (tr.symbol._mangled, offset)
        elif scope == 'parameter':
            emmit('paddr', '%i' % (tr.symbol.offset - offset), tr.t)
            t1 = tr.t         
        elif scope == 'local':
            emmit('paddr', '%i' % -(tr.symbol.offset - offset), tr.t)
            t1 = tr.t         

        tr = tree.next[1]
        scope = tr.symbol.scope
        offset = 1 + 2 * tr.symbol.count
        if scope == 'global':
            #emmit('loadu16', tr.symbol.t, '#%s + %i' % (tr.symbol._mangled, offset))
            t2 = "#%s + %i" % (tr.symbol._mangled, offset)
        elif scope == 'parameter':
            emmit('paddr', '%i' % (tr.symbol.offset - offset), tr.t)
            t2 = tr.t         
        elif scope == 'local':
            emmit('paddr', '%i' % -(tr.symbol.offset - offset), tr.t)
            t2 = tr.t         

        t = optemps.new_t()
        if tr._type != 'string':
            emmit('loadu16', t, '%i' % tr.symbol.total_size)
            emmit('memcopy', t1, t2, t)
        else:
            emmit('loadu16', t, '%i' % (tr.symbol.total_size / TYPE_SIZES[tr._type]))
            emmit('call', 'STR_ARRAYCOPY', 0)
            REQUIRES.add('strarraycpy.asm')

    elif tree.token == 'LET':
        if O_LEVEL() < 2 or tree.next[0].symbol.accessed or tree.next[1].token == 'CONST':
            traverse(tree.next[1])

        emmit_let_left_part(tree)

    elif tree.token == 'LETARRAY':
        if O_LEVEL() > 1 and not tree.next[0].symbol.entry.accessed:
            return

        traverse(tree.next[1])
        scope = tree.next[0].symbol.scope

        if len(tree.next) <=  2 or tree.next[2] is None:
            traverse(tree.next[0])

            if scope == 'global':
                emmit('astore' + TSUFFIX[tree.next[0]._type], tree.next[0].symbol._mangled, tree.next[1].t)
            elif scope == 'parameter':
                emmit('pastore' + TSUFFIX[tree.next[0]._type], tree.next[0].symbol.entry.offset, tree.next[1].t)
            elif scope == 'local':
                emmit('pastore' + TSUFFIX[tree.next[0]._type], -tree.next[0].symbol.entry.offset, tree.next[1].t)
        else:
            offset = 1 + 2 * tree.next[0].symbol.entry.count + tree.next[2].value
            name = tree.next[0].symbol.entry._mangled
            if scope == 'global':
                emmit('store' + TSUFFIX[tree.next[0]._type], '%s + %i' % (name, offset), tree.next[1].t)
            elif scope == 'parameter':
                emmit('pstore' + TSUFFIX[tree.next[0]._type], tree.next[0].symbol.entry.offset - offset, tree.next[1].t)
            elif scope == 'local':
                emmit('pstore' + TSUFFIX[tree.next[0]._type], -(tree.next[0].symbol.entry.offset - offset), tree.next[1].t)

    elif tree.token == 'LETSUBSTR':
        traverse(tree.next[3])
        emmit('paramstr', tree.next[3].t)

        if tree.next[3].token != 'STRING' and (tree.next[3].token != 'ID' or tree.next[3].symbol._mangled[0] != '_'):
            emmit('paramu8', 1) # If the argument is not a variable, it must be freed
        else:
            emmit('paramu8', 0)

        traverse(tree.next[1])
        emmit('paramu16', tree.next[1].t)

        traverse(tree.next[2])
        emmit('paramu16', tree.next[2].t)

        emmit('fparamu16', tree.next[0].t)
        emmit('call', '__LETSUBSTR', 0)
        REQUIRES.add('letsubstr.asm')

    elif tree.token == 'WHILE':
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        LOOPS.append(('WHILE', end_loop, loop_label)) # Saves which labels to jump upon EXIT or CONTINUE

        emmit('label', loop_label)
        traverse(tree.next[0])
        emmit('jzero' + TSUFFIX[tree.next[0]._type], tree.next[0].t, end_loop)

        if len(tree.next) > 1:
            traverse(tree.next[1])

        emmit('jump', loop_label)
        emmit('label', end_loop)
        LOOPS.pop()
        del loop_label, end_loop

    elif tree.token == 'DO_LOOP':
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        LOOPS.append(('DO', end_loop, loop_label)) # Saves which labels to jump upon EXIT or CONTINUE

        emmit('label', loop_label)
        if len(tree.next):
            traverse(tree.next[0])
        emmit('jump', loop_label)
        emmit('label', end_loop)
        LOOPS.pop()
        del loop_label, end_loop

    elif tree.token in ('DO_UNTIL', 'UNTIL_DO'):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        continue_loop = backend.tmp_label()

        if tree.token == 'UNTIL_DO':
            emmit('jump', continue_loop)

        emmit('label', loop_label)
        LOOPS.append(('DO', end_loop, continue_loop)) # Saves which labels to jump upon EXIT or CONTINUE

        if len(tree.next) > 1:
            traverse(tree.next[1])

        emmit('label', continue_loop)
        traverse(tree.next[0])
        emmit('jzero' + TSUFFIX[tree.next[0]._type], tree.next[0].t, loop_label)
        emmit('label', end_loop)
        LOOPS.pop()
        del loop_label, end_loop, continue_loop

    elif tree.token in ('DO_WHILE', 'WHILE_DO'):
        loop_label = backend.tmp_label()
        end_loop = backend.tmp_label()
        continue_loop = backend.tmp_label()

        if tree.token == 'WHILE_DO':
            emmit('jump', continue_loop)

        emmit('label', loop_label)
        LOOPS.append(('DO', end_loop, continue_loop)) # Saves which labels to jump upon EXIT or CONTINUE

        if len(tree.next) > 1:
            traverse(tree.next[1])

        emmit('label', continue_loop)
        traverse(tree.next[0])
        emmit('jnzero' + TSUFFIX[tree.next[0]._type], tree.next[0].t, loop_label)
        emmit('label', end_loop)
        LOOPS.pop()
        del loop_label, end_loop, continue_loop

    elif tree.token == 'EXIT_DO':
        emmit('jump', loop_exit_label('DO'))

    elif tree.token == 'EXIT_WHILE':
        emmit('jump', loop_exit_label('WHILE'))

    elif tree.token == 'EXIT_FOR':
        emmit('jump', loop_exit_label('FOR'))

    elif tree.token == 'CONTINUE_DO':
        emmit('jump', loop_cont_label('DO'))

    elif tree.token == 'CONTINUE_WHILE':
        emmit('jump', loop_cont_label('WHILE'))

    elif tree.token == 'CONTINUE_FOR':
        emmit('jump', loop_cont_label('FOR'))

    elif tree.token == 'IF':
        if_label_else = backend.tmp_label()
        if_label_endif = backend.tmp_label()
        traverse(tree.next[0])

        if len(tree.next) == 3: # Has else?
            emmit('jzero' + TSUFFIX[tree.next[0]._type], tree.next[0].t, if_label_else)
        else:
            emmit('jzero' + TSUFFIX[tree.next[0]._type], tree.next[0].t, if_label_endif)

        traverse(tree.next[1]) # THEN...

        if len(tree.next) == 3: # Has else?
            emmit('jump', if_label_endif)
            emmit('label', if_label_else)
            traverse(tree.next[2])

        emmit('label', if_label_endif)

    elif tree.token == 'FUNCDECL':
        if O_LEVEL() > 0 and not tree.symbol.entry.accessed:
            warning(tree.symbol.entry.lineno, "Function '%s' is never called and has been ignored" % tree.symbol.entry.id)
        else:
            tree.symbol.token = 'FUNCTION' # Delay emission of functions 'til the end
            FUNCTIONS.append(tree)

    elif tree.token == 'FUNCTION':
        emmit('label', tree.symbol._mangled)

        if tree.symbol.entry.convention == '__fastcall__':
            emmit('enter', '__fastcall__')
        else:
            emmit('enter', tree.symbol.locals_size)

        for local_var in tree.symbol.local_symbol_table.values():
            if not local_var.accessed:
                warning_not_used(local_var.lineno, local_var.id)

            if local_var._class == 'array':
                l = [x.size for x in local_var.bounds.next[1:]]
                l = [len(l)] + l # Prepends len(l) (number of dimentions - 1)
                q = []
                for x in l:
                    q.append('%02X' % (x & 0xFF))
                    q.append('%02X' % (x >> 8))

                q.append('%02X' % local_var.size)
                if local_var.default_value is not None:
                    q.extend(array_default_value(local_var._type, local_var.default_value))
                emmit('lvard', local_var.offset, q) # Initalizes array bounds
            elif local_var._class == 'const':
                continue
            else:
                if local_var.default_value is not None and local_var.default_value != 0: # Local vars always defaults to 0, so if 0 we do nothing
                    if isinstance(local_var.default_value, SymbolCONST) and \
                        local_var.default_value.token == 'CONST':
                        emmit('lvarx', local_var.offset, local_var._type, [traverse_const(local_var.default_value)])
                    else:
                        q = default_value(local_var._type, local_var.default_value)
                        emmit('lvard', local_var.offset, q)

        for i in tree.next:
            traverse(i)

        emmit('label', '%s__leave' % tree.symbol._mangled)

        # Now free any local string from memory.
        preserve_hl = False
        for local_var in tree.symbol.local_symbol_table.values():
            if local_var._type == 'string': # Only if it's string we free it
                scope = local_var.scope
                if local_var._class != 'array': # Ok just free it
                    if scope == 'local' or (scope == 'parameter' and not local_var.byref):
                        if not preserve_hl:
                            preserve_hl = True
                            emmit('exchg')

                        offset = -local_var.offset if scope == 'local' else local_var.offset
                        emmit('fploadstr', local_var.t, offset)
                        emmit('call', '__MEM_FREE', 0)
                        REQUIRES.add('free.asm')
                elif local_var._class == 'const':
                    continue
                else: # This is an array of strings, we must free it unless it's a by_ref array
                    if scope == 'local' or (scope == 'parameter' and not local_var.byref):
                        if not preserve_hl:
                            preserve_hl = True
                            emmit('exchg')

                        offset = -local_var.offset if scope == 'local' else local_var.offset
                        elems = reduce(lambda x, y: x * y, [x.size for x in local_var.bounds.next])
                        emmit('paramu16', elems)
                        emmit('paddr', offset, local_var.t)
                        emmit('fparamu16', local_var.t)
                        emmit('call', '__ARRAY_FREE', 0)
                        REQUIRES.add('arrayfree.asm')

        if preserve_hl:
            emmit('exchg')

        if tree.symbol.entry.convention == '__fastcall__':
            emmit('leave', '__fastcall__')
        else:
            emmit('leave', tree.symbol.params_size)

    elif tree.token == 'ARGLIST':
        for i in range(tree.symbol.count - 1, -1, -1):
            traverse(tree.next[i])

    elif tree.token == 'ARGUMENT':
        if not tree.symbol.byref:
            if tree.next[0].token == 'ID' and \
                tree.symbol._type == 'string' and tree.next[0].t[0] == '$':
                    tree.next[0].t = optemps.new_t()

            traverse(tree.next[0])
            emmit('param' + TSUFFIX[tree.symbol._type], tree.next[0].t)
        else:
            scope = tree.symbol.arg.scope
            if tree.t[0] == '_':
                t = optemps.new_t()
            else:
                t = tree.t

            if scope == 'global':
                emmit('loadu16', t, '#' + tree.symbol._mangled)
            elif scope == 'parameter': # A function has used a parameter as an argument to another function call
                if not tree.symbol.arg.byref: # It's like a local variable
                    emmit('paddr', tree.symbol.arg.offset, t)
                else:
                    emmit('ploadu16', t, str(tree.symbol.arg.offset))
            elif scope == 'local':
                emmit('paddr', -tree.symbol.arg.offset, t)

            emmit('paramu16', t)

    elif tree.token == 'FUNCCALL': # Calls a Function, and the result is returned in registers
        traverse(tree.next[0]) # Arg list

        if tree.symbol.entry.convention == '__fastcall__':
            if tree.next[0].symbol.count > 0: # At least
                t = optemps.new_t()
                emmit('fparam' + TSUFFIX[tree.next[0].next[0]._type], t)

        emmit('call', tree.symbol.entry._mangled, tree.symbol.entry.size)

    elif tree.token == 'CALL': # Calls a SUB or a Function discarding its return value
        traverse(tree.next[0]) # Arg list
        if tree.symbol.entry.convention == '__fastcall__':
            if tree.next[0].symbol.count > 0: # At least
                t = optemps.new_t()
                emmit('fparam' + TSUFFIX[tree.next[0].next[0]._type], t)

        emmit('call', tree.symbol.entry._mangled, 0) # Procedure call. Discard return

        if tree.symbol.entry.kind == 'function' and tree.symbol.entry._type == 'string':
            emmit('call', '__MEM_FREE', 0) # Discard string return value if the called function has any
            REQUIRES.add('free.asm')

    elif tree.token == 'RETURN':
        if len(tree.next) == 2: # Something to return?
            traverse(tree.next[1])
            emmit('ret' + TSUFFIX[tree.next[1]._type], tree.next[1].t, '%s__leave' % tree.next[0].symbol._mangled)
        elif len(tree.next) == 1:
            emmit('ret', '%s__leave' % tree.next[0].symbol._mangled)
        else:
            emmit('leave', '__fastcall__')

    elif tree.token == 'FOR':
        loop_label_start = backend.tmp_label()
        loop_label_lt = backend.tmp_label()
        loop_label_gt = backend.tmp_label()
        end_loop = backend.tmp_label()
        loop_body = backend.tmp_label()
        loop_continue = backend.tmp_label()
        suffix = TSUFFIX[tree.next[0]._type]

        LOOPS.append(('FOR', end_loop, loop_continue)) # Saves which label to jump upon EXIT FOR and CONTINUE FOR

        traverse(tree.next[1]) # Get starting value (lower limit)
        emmit_let_left_part(tree) # Store it in the iterator variable
        emmit('jump', loop_label_start)

        # FOR body statements
        emmit('label', loop_body)
        traverse(tree.next[4]) 

        # Jump here to continue next iteration
        emmit('label', loop_continue)

        # VAR = VAR + STEP
        traverse(tree.next[0]) # Iterator Var
        traverse(tree.next[3]) # Step
        t = optemps.new_t()
        emmit('add' + suffix, t, tree.next[0].t, tree.next[3].t)
        emmit_let_left_part(tree, t)

        # Loop starts here
        emmit('label', loop_label_start)

        # Emmit condition
        if is_number(tree.next[3]) or is_unsigned(tree.next[3]._type):
            direct = True
        else:
            direct = False
            traverse(tree.next[3]) # Step
            emmit('jgezero' + suffix, tree.next[3].t, loop_label_gt)

        if not direct or tree.next[3].value < 0: # Here for negative steps
                                # Compares if var < limit2
            traverse(tree.next[0])  # Value of var
            traverse(tree.next[2])  # Value of limit2
            emmit('lt' + suffix, tree.t, tree.next[0].t, tree.next[2].t)
            emmit('jzerou8', tree.t, loop_body)

        if not direct:
            emmit('jump', end_loop)
            emmit('label', loop_label_gt)

        if not direct or tree.next[3].value >= 0: # Here for positive steps
                                   # Compares if var > limit2
            traverse(tree.next[0])  # Value of var
            traverse(tree.next[2])  # Value of limit2
            emmit('gt' + suffix, tree.t, tree.next[0].t, tree.next[2].t)
            emmit('jzerou8', tree.t, loop_body)
    
        emmit('label', end_loop)
        LOOPS.pop()

        del loop_label_start, end_loop, loop_label_gt, loop_label_lt, loop_body, loop_continue

    elif tree.token == 'SAVE': # The Save command. Only SAVE <string> CODE x, y supported
        traverse(tree.next[0])
        emmit('paramstr', tree.next[0].t)
        traverse(tree.next[1])
        emmit('paramu16', tree.next[1].t)
        traverse(tree.next[2])
        emmit('paramu16', tree.next[2].t)
        emmit('call', 'SAVE_CODE', 0)
        REQUIRES.add('save.asm')

    elif tree.token in ('LOAD', 'VERIFY'):
        traverse(tree.next[0])
        emmit('paramstr', tree.next[0].t)
        traverse(tree.next[1])
        emmit('paramu16', tree.next[1].t)
        traverse(tree.next[2])
        emmit('paramu16', tree.next[2].t)
        emmit('paramu8', int (tree.token == 'LOAD'))
        emmit('call', 'LOAD_CODE', 0)
        REQUIRES.add('load.asm')

    elif tree.token == 'RANDOMIZE':
        traverse(tree.next[0])
        emmit('fparamu32', tree.next[0].t)
        emmit('call', 'RANDOMIZE', 0)
        REQUIRES.add('random.asm')

    elif tree.token == 'PRINT': # The print sentence
        for i in tree.next:
            traverse(i)

            # Print subcommands (AT, OVER, INK, etc... must be skipped here)
            if i.token in ('PRINT_TAB', 'PRINT_AT', 'PRINT_COMMA',) + ATTR_TMP: continue
            emmit('fparam' + TSUFFIX[i._type], i.t)
            emmit('call', '__PRINT' + TSUFFIX[i._type].upper(), 0)
            REQUIRES.add('print' + TSUFFIX[i._type].lower() + '.asm')

        for i in tree.next:
            if i.token in ATTR_TMP or has_control_chars(i):
                HAS_ATTR = True
                break

        if tree.symbol.eol:
            if HAS_ATTR:
                emmit('call', 'PRINT_EOL_ATTR', 0)
                REQUIRES.add('print_eol_attr.asm')
                HAS_ATTR = False
            else:
                emmit('call', 'PRINT_EOL', 0)
                REQUIRES.add('print.asm')

    elif tree.token == 'PRINT_AT': # AT implemented as a sentence
        traverse(tree.next[0])
        emmit('paramu8', tree.next[0].t)
        traverse(tree.next[1])
        emmit('fparamu8', tree.next[1].t)
        emmit('call', 'PRINT_AT', 0) # Procedure call. Discard return
        REQUIRES.add('print.asm')

    elif tree.token == 'PRINT_TAB':
        traverse(tree.next[0])
        emmit('fparamu8', tree.next[0].t)
        emmit('call', 'PRINT_TAB', 0)
        REQUIRES.add('print.asm')

    elif tree.token == 'PRINT_COMMA':
        emmit('call', 'PRINT_COMMA', 0)
        REQUIRES.add('print.asm')

    elif tree.token in ATTR_TMP:
        traverse(tree.next[0])
        emmit('fparamu8', tree.next[0].t)
        emmit('call', tree.token, 0) # Procedure call. Discard return
        ifile = tree.token.lower()
        ifile = ifile[:ifile.index('_')]
        REQUIRES.add(ifile + '.asm')

    elif tree.token == 'ASM':
        emmit('inline', tree.symbol.text, tree.symbol.lineno)

    elif tree.token == 'LABEL':
        emmit('label', tree.next[0].symbol._mangled)
        for tmp in tree.next[0].symbol.aliased_by:
            emmit('label', tmp._mangled)

    elif tree.token == 'GOTO':
        emmit('jump', tree.next[0].symbol._mangled)

    elif tree.token == 'GOSUB':
        emmit('call', tree.next[0].symbol._mangled, 0)

    elif tree.token == 'CHKBREAK' and PREV_TOKEN != tree.token:
        emmit('fparamu16', tree.next[0].t)
        emmit('call', 'CHECK_BREAK', 0)
        REQUIRES.add('break.asm')

    norm_attr()



def emmit_strings():
    for str in STRING_LABELS.keys():
        l = '%04X' % (len(str) & 0xFFFF)
        emmit('vard', STRING_LABELS[str], [l] + ['%02X' % ord(x) for x in str])


