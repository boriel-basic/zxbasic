#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: et:ts=4:sw=4:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Parser for the ZXBASM (ZXBasic Assembler)
# ----------------------------------------------------------------------

import os
import re
import asmlex
import ply.yacc as yacc

from asmlex import tokens  # noqa
from asm import AsmInstruction, Error
from ast_ import Ast
from api.debug import __DEBUG__
from api.config import OPTIONS
from api.errmsg import syntax_error as error
from api.errmsg import warning
from api import global_ as gl
import api.utils
import zxbpp
import outfmt

LEXER = asmlex.Lexer()

ORG = 0  # Origin of CODE
INITS = []
MEMORY = None  # Memory for instructions (Will be initialized with a Memory() instance)
AUTORUN_ADDR = None  # Where to start the execution automatically
RE_DOTS = re.compile(r'\.+')

REGS16 = {'BC', 'DE', 'HL', 'SP', 'IX', 'IY'}  # 16 Bits registers

precedence = (
    ('left', 'RSHIFT', 'LSHIFT', 'BAND', 'BOR', 'BXOR'),
    ('left', 'PLUS', 'MINUS'),
    ('left', 'MUL', 'DIV', 'MOD'),
    ('right', 'POW'),
    ('right', 'UMINUS'),
)

MAX_MEM = 65535  # Max memory limit
DOT = '.'  # NAMESPACE separator
GLOBAL_NAMESPACE = DOT
NAMESPACE = GLOBAL_NAMESPACE  # Current namespace (defaults to ''). It's a prefix added to each global label


def normalize_namespace(namespace):
    """ Given a namespace (e.g. '.' or 'mynamespace'),
    returns it in normalized form. That is:
        - always prefixed with a dot
        - no trailing dots
        - any double dots are converted to single dot (..my..namespace => .my.namespace)
        - one or more dots (e.g. '.', '..', '...') are converted to '.' (Global namespace)
    """
    namespace = (DOT + DOT.join(RE_DOTS.split(namespace))).rstrip(DOT) + DOT
    return namespace


def init():
    """ Initializes this module
    """
    global ORG
    global LEXER
    global MEMORY
    global INITS
    global AUTORUN_ADDR
    global NAMESPACE

    ORG = 0  # Origin of CODE
    INITS = []
    MEMORY = None  # Memory for instructions (Will be initialized with a Memory() instance)
    AUTORUN_ADDR = None  # Where to start the execution automatically
    NAMESPACE = GLOBAL_NAMESPACE  # Current namespace (defaults to ''). It's a prefix added to each global label
    gl.has_errors = 0
    gl.error_msg_cache.clear()


class Asm(AsmInstruction):
    """ Class extension to AsmInstruction with a short name :-P
    and will trap some exceptions and convert them to error msgs.

    It will also record source line
    """

    def __init__(self, lineno, asm, arg=None):
        self.lineno = lineno

        if asm not in ('DEFB', 'DEFS', 'DEFW'):
            try:
                super(Asm, self).__init__(asm, arg)
            except Error as v:
                error(lineno, v.msg)
                return

            self.pending = len([x for x in self.arg if isinstance(x, Expr) and x.try_eval() is None]) > 0

            if not self.pending:
                self.arg = self.argval()
        else:
            self.asm = asm
            self.pending = True

            if isinstance(arg, str):
                self.arg = tuple([Expr(Container(ord(x), lineno)) for x in arg])
            else:
                self.arg = arg

            self.arg_num = len(self.arg)

    def bytes(self):
        """ Returns opcodes
        """
        if self.asm not in ('DEFB', 'DEFS', 'DEFW'):
            if self.pending:
                tmp = self.arg  # Saves current arg temporarily
                self.arg = tuple([0] * self.arg_num)
                result = super(Asm, self).bytes()
                self.arg = tmp  # And recovers it

                return result

            return super(Asm, self).bytes()

        if self.asm == 'DEFB':
            if self.pending:
                return tuple([0] * self.arg_num)

            return tuple([x & 0xFF for x in self.argval()])

        if self.asm == 'DEFS':
            if self.pending:
                N = self.arg[0]
                if isinstance(N, Expr):
                    N = N.eval()
                return tuple([0] * N)  # ??

            args = self.argval()
            num = args[1] & 0xFF
            return tuple([num] * args[0])

        if self.pending:  # DEFW
            return tuple([0] * 2 * self.arg_num)

        result = ()
        for i in self.argval():
            x = i & 0xFFFF
            result += (x & 0xFF, x >> 8)

        return result

    def argval(self):
        """ Solve args values or raise errors if not
        defined yet
        """
        if gl.has_errors:
            return [None]

        if self.asm in ('DEFB', 'DEFS', 'DEFW'):
            return tuple([x.eval() if isinstance(x, Expr) else x for x in self.arg])

        self.arg = tuple([x if not isinstance(x, Expr) else x.eval() for x in self.arg])
        if gl.has_errors:
            return [None]

        if self.asm.split(' ')[0] in ('JR', 'DJNZ'):  # A relative jump?
            if self.arg[0] < -128 or self.arg[0] > 127:
                error(self.lineno, 'Relative jump out of range')
                return [None]

        return super(Asm, self).argval()


class Container(object):
    """ Single class container
    """

    def __init__(self, item, lineno):
        """ Item to store
        """
        self.item = item
        self.lineno = lineno


class Expr(Ast):
    """ A class derived from AST that will
    recursively parse its nodes and return the value
    """
    ignore = True  # Class flag
    funct = {
        '-': lambda x, y: x - y,
        '+': lambda x, y: x + y,
        '*': lambda x, y: x * y,
        '/': lambda x, y: x // y,
        '^': lambda x, y: x ** y,
        '%': lambda x, y: x % y,
        '&': lambda x, y: x & y,
        '|': lambda x, y: x | y,
        '~': lambda x, y: x ^ y,
        '<<': lambda x, y: x << y,
        '>>': lambda x, y: x >> y
    }

    def __init__(self, symbol=None):
        """ Initializes ancestor attributes, and
        ignore flags.
        """
        Ast.__init__(self)
        self.symbol = symbol

    @property
    def left(self):
        if self.children:
            return self.children[0]

    @left.setter
    def left(self, value):
        if self.children:
            self.children[0] = value
        else:
            self.children.append(value)

    @property
    def right(self):
        if len(self.children) > 1:
            return self.children[1]

    @right.setter
    def right(self, value):
        if len(self.children) > 1:
            self.children[1] = value
        elif self.children:
            self.children.append(value)
        else:
            self.children = [None, value]

    def eval(self):
        """ Recursively evals the node. Exits with an
        error if not resolved.
        """
        Expr.ignore = False
        result = self.try_eval()
        Expr.ignore = True

        return result

    def try_eval(self):
        """ Recursively evals the node. Returns None
        if it is still unresolved.
        """
        item = self.symbol.item

        if isinstance(item, int):
            return item

        if isinstance(item, Label):
            if item.defined:
                if isinstance(item.value, Expr):
                    return item.value.try_eval()
                else:
                    return item.value
            else:
                if Expr.ignore:
                    return None

                # Try to resolve into the global namespace
                error(self.symbol.lineno, "Undefined label '%s'" % item.name)
                return None

        try:
            if isinstance(item, tuple):
                return tuple([x.try_eval() for x in item])

            if isinstance(item, list):
                return [x.try_eval() for x in item]

            if item == '-' and len(self.children) == 1:
                return -self.left.try_eval()

            try:
                return self.funct[item](self.left.try_eval(), self.right.try_eval())
            except ZeroDivisionError:
                error(self.symbol.lineno, 'Division by 0')
            except KeyError:
                pass

        except TypeError:
            pass

        return None


class Label(object):
    """ A class to store Label information (NAME, linenumber and Address)
    """

    def __init__(self, name, lineno, value=None, local=False, namespace=None, is_address=False):
        """ Defines a Label object:
                - name : The label name. e.g. __LOOP
                - lineno : Where was this label defined.
                - address : Memory address or numeric value this label refers
                            to (None if undefined yet)
                - local : whether this is a local label or a global one
                - namespace: If the label is DECLARED (not accessed), this is
                        its prefixed namespace
                - is_address: Whether this label refers to a memory address (declared without EQU)
        """
        self._name = name
        self.lineno = lineno
        self.value = value
        self.local = local
        self.namespace = namespace
        self.current_namespace = NAMESPACE  # Namespace under which the label was referenced (not declared)
        self.is_address = is_address

    @property
    def defined(self):
        """ Returns whether it has a value already or not.
        """
        return self.value is not None

    def define(self, value, lineno, namespace=None):
        """ Defines label value. It can be anything. Even an AST
        """
        if self.defined:
            error(lineno, "label '%s' already defined at line %i" % (self.name, self.lineno))

        self.value = value
        self.lineno = lineno
        self.namespace = NAMESPACE if namespace is None else namespace

    def resolve(self, lineno):
        """ Evaluates label value. Exits with error (unresolved) if value is none
        """
        if not self.defined:
            error(lineno, "Undeclared label '%s'" % self.name)

        if isinstance(self.value, Expr):
            return self.value.eval()

        return self.value

    @property
    def name(self):
        return self._name


class Memory(object):
    """ A class to describe memory
    """

    def __init__(self, org=0):
        """ Initializes the origin of code.
        0 by default """
        self.index = org  # ORG address (can be changed on the fly)
        self.memory_bytes = {}  # An array (associative) containing memory bytes
        self.local_labels = [{}]  # Local labels in the current memory scope
        self.global_labels = self.local_labels[0]  # Global memory labels
        self.orgs = {}  # Origins of code for asm mnemonics. This will store corresponding asm instructions
        self.ORG = org  # last ORG value set
        self.scopes = []

    def enter_proc(self, lineno):
        """ Enters (pushes) a new context
        """
        self.local_labels.append({})  # Add a new context
        self.scopes.append(lineno)
        __DEBUG__('Entering scope level %i at line %i' % (len(self.scopes), lineno))

    def set_org(self, value, lineno):
        """ Sets a new ORG value
        """
        if value < 0 or value > MAX_MEM:
            error(lineno, "Memory ORG out of range [0 .. 65535]. Current value: %i" % value)

        self.index = self.ORG = value

    @staticmethod
    def id_name(label, namespace=None):
        """ Given a name and a namespace, resolves
        returns the name as namespace + '.' + name. If namespace
        is none, the current NAMESPACE is used
        """
        if not label.startswith(DOT):
            if namespace is None:
                namespace = NAMESPACE
            ex_label = namespace + label  # The mangled namespace.labelname label
        else:
            if namespace is None:
                namespace = GLOBAL_NAMESPACE  # Global namespace
            ex_label = label

        return ex_label, namespace

    @property
    def org(self):
        """ Returns current ORG index
        """
        return self.index

    def __set_byte(self, byte, lineno):
        """ Sets a byte at the current location,
        and increments org in one. Raises an error if org > MAX_MEMORY
        """
        if byte < 0 or byte > 255:
            error(lineno, 'Invalid byte value %i' % byte)

        self.memory_bytes[self.org] = byte
        self.index += 1  # Increment current memory pointer

    def exit_proc(self, lineno):
        """ Exits current procedure. Local labels are transferred to global
        scope unless they have been marked as local ones.

        Raises an error if no current local context (stack underflow)
        """
        __DEBUG__('Exiting current scope from lineno %i' % lineno)

        if len(self.local_labels) <= 1:
            error(lineno, 'ENDP in global scope (with no PROC)')
            return

        for label in self.local_labels[-1].values():
            if label.local:
                if not label.defined:
                    error(lineno, "Undefined LOCAL label '%s'" % label.name)
                    return
                continue

            name = label.name
            _lineno = label.lineno
            value = label.value

            if name not in self.global_labels.keys():
                self.global_labels[name] = label
            else:
                self.global_labels[name].define(value, _lineno)

        self.local_labels.pop()  # Removes current context
        self.scopes.pop()

    def set_memory_slot(self):
        if self.org not in self.orgs.keys():
            self.orgs[self.org] = ()  # Declares an empty memory slot if not already done
            self.memory_bytes[self.org] = ()  # Declares an empty memory slot if not already done

    def add_instruction(self, instr):
        """ This will insert an asm instruction at the current memory position
        in a t-uple as (mnemonic, params).

        It will also insert the opcodes at the memory_bytes
        """
        if gl.has_errors:
            return

        __DEBUG__('%04Xh [%04Xh] ASM: %s' % (self.org, self.org - self.ORG, instr.asm))
        self.set_memory_slot()
        self.orgs[self.org] += (instr,)

        for byte in instr.bytes():
            self.__set_byte(byte, instr.lineno)

    def dump(self):
        """ Returns a tuple containing code ORG, and a list of OUTPUT
        """
        org = min(self.memory_bytes.keys())  # Org is the lowest one
        OUTPUT = []
        align = []

        for i in range(org, max(self.memory_bytes.keys()) + 1):
            if gl.has_errors:
                return org, OUTPUT

            try:
                try:
                    a = [x for x in self.orgs[i] if isinstance(x, Asm)]  # search for asm instructions

                    if not a:
                        align.append(0)  # Fill with ZEROes not used memory regions
                        continue

                    OUTPUT += align
                    align = []
                    a = a[0]
                    if a.pending:
                        a.arg = a.argval()
                        a.pending = False
                        tmp = a.bytes()

                        for r in range(len(tmp)):
                            self.memory_bytes[i + r] = tmp[r]
                except KeyError:
                    pass

                OUTPUT.append(self.memory_bytes[i])

            except KeyError:
                OUTPUT.append(0)  # Fill with ZEROes not used memory regions

        return org, OUTPUT

    def declare_label(self, label, lineno, value=None, local=False, namespace=None):
        """ Sets a label with the given value or with the current address (org)
        if no value is passed.

        Exits with error if label already set,
        otherwise return the label object
        """
        ex_label, namespace = Memory.id_name(label, namespace)

        is_address = value is None
        if value is None:
            value = self.org

        if ex_label in self.local_labels[-1].keys():
            self.local_labels[-1][ex_label].define(value, lineno)
            self.local_labels[-1][ex_label].is_address = is_address
        else:
            self.local_labels[-1][ex_label] = Label(ex_label, lineno, value, local, namespace, is_address)

        self.set_memory_slot()

        return self.local_labels[-1][ex_label]

    def get_label(self, label, lineno):
        """ Returns a label in the current context or in the global one.
        If the label does not exists, creates a new one and returns it.
        """
        global NAMESPACE

        ex_label, namespace = Memory.id_name(label)

        for i in range(len(self.local_labels) - 1, -1, -1):  # Downstep
            result = self.local_labels[i].get(ex_label, None)
            if result is not None:
                return result

        result = Label(ex_label, lineno, namespace=namespace)
        self.local_labels[-1][ex_label] = result  # HINT: no namespace

        return result

    def set_label(self, label, lineno, local=False):
        """ Sets a label, lineno and local flag in the current scope
        (even if it exist in previous scopes). If the label exist in
        the current scope, changes it flags.

        The resulting label is returned.
        """
        ex_label, namespace = Memory.id_name(label)

        if ex_label in self.local_labels[-1].keys():
            result = self.local_labels[-1][ex_label]
            result.lineno = lineno
        else:
            result = self.local_labels[-1][ex_label] = Label(ex_label, lineno, namespace=NAMESPACE)

        if result.local == local:
            warning(lineno, "label '%s' already declared as LOCAL" % label)

        result.local = local

        return result

    @property
    def memory_map(self):
        """ Returns a (very long) string containing a memory map
            hex address: label
        """
        return '\n'.join(sorted("%04X: %s" % (x.value, x.name) for x in self.global_labels.values() if x.is_address))


# -------- GRAMMAR RULES for the preprocessor ---------

def p_start(p):
    """ start : program
              | program endline
    """


def p_program_endline(p):
    """ endline : END NEWLINE
    """


def p_program_endline2(p):
    """ endline : END expr NEWLINE
                | END pexpr NEWLINE
    """
    global AUTORUN_ADDR
    AUTORUN_ADDR = p[2].eval()


def p_program(p):
    """ program : line
    """


def p_program_line(p):
    """ program : program line
    """


def p_def_label(p):
    """ line : ID EQU expr NEWLINE
             | ID EQU pexpr NEWLINE
    """
    p[0] = None
    __DEBUG__("Declaring '%s%s' in %i" % (NAMESPACE, p[1], p.lineno(1)))
    MEMORY.declare_label(p[1], p.lineno(1), p[3])


def p_line_asm(p):
    """ line : asms NEWLINE
             | asms CO NEWLINE
    """


def p_asms_empty(p):
    """ asms :
    """
    p[0] = MEMORY.org


def p_asms_asm(p):
    """ asms : asm
    """
    p[0] = MEMORY.org
    asm = p[1]
    if isinstance(asm, Asm):
        MEMORY.add_instruction(asm)


def p_asms_asms_asm(p):
    """ asms : asms CO asm
    """
    p[0] = p[1]
    asm = p[3]
    if isinstance(asm, Asm):
        MEMORY.add_instruction(asm)


def p_asm_label(p):
    """ asm : ID
    """
    __DEBUG__("Declaring '%s%s' (value %04Xh) in %i" % (NAMESPACE, p[1], MEMORY.org, p.lineno(1)))
    MEMORY.declare_label(p[1], p.lineno(1))


def p_asm_ld8(p):
    """ asm : LD reg8 COMMA reg8_hl
            | LD reg8_hl COMMA reg8
            | LD reg8 COMMA reg8
            | LD SP COMMA HL
            | LD SP COMMA reg16i
            | LD A COMMA reg8
            | LD reg8 COMMA A
            | LD reg8_hl COMMA A
            | LD A COMMA reg8_hl
            | LD A COMMA A
            | LD A COMMA I
            | LD I COMMA A
            | LD A COMMA R
            | LD R COMMA A
            | LD A COMMA reg8i
            | LD reg8i COMMA A
            | LD reg8 COMMA reg8i
            | LD reg8i COMMA regBCDE
            | LD reg8i COMMA reg8i
    """
    if p[2] in ('H', 'L') and p[4] in ('IXH', 'IXL', 'IYH', 'IYL'):
        p[0] = None
        error(p.lineno(0), "Unexpected token '%s'" % p[4])
    else:
        p[0] = Asm(p.lineno(1), 'LD %s,%s' % (p[2], p[4]))


def p_LDa(p):  # Remaining LD A,... and LD...,A instructions
    """ asm : LD A COMMA LP BC RP
            | LD A COMMA LP DE RP
            | LD LP BC RP COMMA A
            | LD LP DE RP COMMA A
    """
    p[0] = Asm(p.lineno(1), 'LD ' + ''.join(p[2:]))


def p_PROC(p):
    """ asm : PROC
    """
    p[0] = None  # Start of a PROC scope
    MEMORY.enter_proc(p.lineno(1))


def p_ENDP(p):
    """ asm : ENDP
    """
    p[0] = None  # End of a PROC scope
    MEMORY.exit_proc(p.lineno(1))


def p_LOCAL(p):
    """ asm : LOCAL id_list
    """
    p[0] = None
    for label, line in p[2]:
        __DEBUG__("Setting label '%s' as local at line %i" % (label, line))

        MEMORY.set_label(label, line, local=True)


def p_idlist(p):
    """ id_list : ID
    """
    p[0] = ((p[1], p.lineno(1)),)


def p_idlist_id(p):
    """ id_list : id_list COMMA ID
    """
    p[0] = p[1] + ((p[3], p.lineno(3)),)


def p_DEFB(p):  # Define bytes
    """ asm : DEFB number_list
            | DEFB STRING
    """
    p[0] = Asm(p.lineno(1), 'DEFB', p[2])


def p_DEFS(p):  # Define bytes
    """ asm : DEFS number_list
    """
    if len(p[2]) > 2:
        error(p.lineno(1), "too many arguments for DEFS")

    if len(p[2]) < 2:
        num = Expr.makenode(Container(0, p.lineno(1)))  # Defaults to 0
        p[2] = p[2] + (num,)

    p[0] = Asm(p.lineno(1), 'DEFS', p[2])


def p_DEFW(p):  # Define words
    """ asm : DEFW number_list
    """
    p[0] = Asm(p.lineno(1), 'DEFW', p[2])


def p_number_list(p):
    """ number_list : expr
                    | pexpr
    """
    p[0] = (p[1],)


def p_number_list_number(p):
    """ number_list : number_list COMMA expr
                    | number_list COMMA pexpr
    """
    p[0] = p[1] + (p[3],)


def p_asm_ldind_r8(p):
    """ asm : LD reg8_I COMMA reg8
            | LD reg8_I COMMA A
    """
    p[0] = Asm(p.lineno(1), 'LD %s,%s' % (p[2][0], p[4]), p[2][1])


def p_asm_ldr8_ind(p):
    """ asm : LD reg8 COMMA reg8_I
            | LD A COMMA reg8_I
    """
    p[0] = Asm(p.lineno(1), 'LD %s,%s' % (p[2], p[4][0]), p[4][1])


def p_reg8_hl(p):
    """ reg8_hl : LP HL RP
    """
    p[0] = '(HL)'


def p_ind8_I(p):
    """    reg8_I : LP IX PLUS expr RP
               | LP IX MINUS expr RP
               | LP IY PLUS expr RP
               | LP IY MINUS expr RP
               | LP IX PLUS pexpr RP
               | LP IX MINUS pexpr RP
               | LP IY PLUS pexpr RP
               | LP IY MINUS pexpr RP
    """
    expr = p[4]
    if p[3] == '-':
        expr = Expr.makenode(Container('-', p.lineno(3)), expr)

    p[0] = ('(%s+N)' % p[2], expr)


def p_ex_af_af(p):
    """ asm : EX AF COMMA AF APO
    """
    p[0] = Asm(p.lineno(1), "EX AF,AF'")


def p_ex_de_hl(p):
    """ asm : EX DE COMMA HL
    """
    p[0] = Asm(p.lineno(1), "EX DE,HL")


def p_org(p):
    """ asm : ORG expr
            | ORG pexpr
    """
    MEMORY.set_org(p[2].eval(), p.lineno(1))


def p_namespace(p):
    """ asm : NAMESPACE ID
    """
    global NAMESPACE

    NAMESPACE = normalize_namespace(p[2])
    __DEBUG__('Setting namespace to ' + (NAMESPACE.rstrip(DOT) or DOT), level=1)


def p_align(p):
    """ asm : ALIGN expr
            | ALIGN pexpr
    """
    align = p[2].eval()
    if align < 2:
        error(p.lineno(1), "ALIGN value must be greater than 1")
        return

    MEMORY.set_org(MEMORY.org + (align - MEMORY.org % align) % align, p.lineno(1))


def p_incbin(p):
    """ asm : INCBIN STRING
    """
    try:
        fname = zxbpp.search_filename(p[2], p.lineno(2), local_first=True)
        if not fname:
            p[0] = None
            return
        with api.utils.open_file(fname, 'rb') as f:
            filecontent = f.read()
    except IOError:
        error(p.lineno(2), "cannot read file '%s'" % p[2])
        p[0] = None
        return

    p[0] = Asm(p.lineno(1), 'DEFB', filecontent)


def p_ex_sp_reg8(p):
    """ asm : EX LP SP RP COMMA reg16i
            | EX LP SP RP COMMA HL
    """
    p[0] = Asm(p.lineno(1), 'EX (SP),' + p[6])


def p_incdec(p):
    """ asm : INC inc_reg
            | DEC inc_reg
    """
    p[0] = Asm(p.lineno(1), '%s %s' % (p[1], p[2]))


def p_incdeci(p):
    """ asm : INC reg8_I
            | DEC reg8_I
    """
    p[0] = Asm(p.lineno(1), '%s %s' % (p[1], p[2][0]), p[2][1])


def p_LD_reg_val(p):
    """ asm : LD reg8 COMMA expr
            | LD reg8 COMMA pexpr
            | LD reg16 COMMA expr
            | LD reg8_hl COMMA expr
            | LD A COMMA expr
            | LD SP COMMA expr
            | LD reg8i COMMA expr
    """
    s = 'LD %s,N' % p[2]
    if p[2] in REGS16:
        s += 'N'

    p[0] = Asm(p.lineno(1), s, p[4])


def p_LD_regI_val(p):
    """ asm : LD reg8_I COMMA expr
    """
    p[0] = Asm(p.lineno(1), 'LD %s,N' % p[2][0], (p[2][1], p[4]))


def p_JP_hl(p):
    """ asm : JP reg8_hl
            | JP LP reg16i RP
    """
    s = 'JP '
    if p[2] == '(HL)':
        s += p[2]
    else:
        s += '(%s)' % p[3]

    p[0] = Asm(p.lineno(1), s)


def p_SBCADD(p):
    """ asm : SBC A COMMA reg8
            | SBC A COMMA reg8i
            | SBC A COMMA A
            | SBC A COMMA reg8_hl
            | SBC HL COMMA SP
            | SBC HL COMMA BC
            | SBC HL COMMA DE
            | SBC HL COMMA HL
            | ADD A COMMA reg8
            | ADD A COMMA reg8i
            | ADD A COMMA A
            | ADD A COMMA reg8_hl
            | ADC A COMMA reg8
            | ADC A COMMA reg8i
            | ADC A COMMA A
            | ADC A COMMA reg8_hl
            | ADD HL COMMA BC
            | ADD HL COMMA DE
            | ADD HL COMMA HL
            | ADD HL COMMA SP
            | ADC HL COMMA BC
            | ADC HL COMMA DE
            | ADC HL COMMA HL
            | ADC HL COMMA SP
            | ADD reg16i COMMA BC
            | ADD reg16i COMMA DE
            | ADD reg16i COMMA HL
            | ADD reg16i COMMA SP
            | ADD reg16i COMMA reg16i
    """
    p[0] = Asm(p.lineno(1), '%s %s,%s' % (p[1], p[2], p[4]))


def p_arith_A_expr(p):
    """ asm : SBC A COMMA expr
            | SBC A COMMA pexpr
            | ADD A COMMA expr
            | ADD A COMMA pexpr
            | ADC A COMMA expr
            | ADC A COMMA pexpr
    """
    p[0] = Asm(p.lineno(1), '%s A,N' % p[1], p[4])


def p_arith_A_regI(p):
    """ asm : SBC A COMMA reg8_I
            | ADD A COMMA reg8_I
            | ADC A COMMA reg8_I
    """
    p[0] = Asm(p.lineno(1), '%s A,%s' % (p[1], p[4][0]), p[4][1])


def p_bitwiseop_reg(p):
    """ asm : bitwiseop reg8
            | bitwiseop reg8i
            | bitwiseop A
            | bitwiseop reg8_hl
    """
    p[0] = Asm(p[1][1], '%s %s' % (p[1][0], p[2]))


def p_bitwiseop_regI(p):
    """ asm : bitwiseop reg8_I
    """
    p[0] = Asm(p[1][1], '%s %s' % (p[1][0], p[2][0]), p[2][1])


def p_bitwise_expr(p):
    """ asm : bitwiseop expr
            | bitwiseop pexpr
    """
    p[0] = Asm(p[1][1], '%s N' % p[1][0], p[2])


def p_bitwise(p):
    """ bitwiseop : OR
              | AND
              | XOR
              | SUB
              | CP
    """
    p[0] = (p[1], p.lineno(1))


def p_PUSH_POP(p):
    """ asm : PUSH AF
            | PUSH reg16
            | POP AF
            | POP reg16
    """
    p[0] = Asm(p.lineno(1), '%s %s' % (p[1], p[2]))


def p_LD_addr_reg(p):  # Load address,reg
    """ asm : LD pexpr COMMA A
            | LD pexpr COMMA reg16
            | LD pexpr COMMA SP
    """
    p[0] = Asm(p.lineno(1), 'LD (NN),%s' % p[4], p[2])


def p_LD_reg_addr(p):  # Load address,reg
    """ asm : LD A COMMA pexpr
            | LD reg16 COMMA pexpr
            | LD SP COMMA pexpr
    """
    p[0] = Asm(p.lineno(1), 'LD %s,(NN)' % p[2], p[4])


def p_ROTATE(p):
    """ asm : rotation reg8
            | rotation reg8_hl
            | rotation A
    """
    p[0] = Asm(p[1][1], '%s %s' % (p[1][0], p[2]))


def p_ROTATE_ix(p):
    """ asm : rotation reg8_I
    """
    p[0] = Asm(p[1][1], '%s %s' % (p[1][0], p[2][0]), p[2][1])


def p_BIT(p):
    """ asm : bitop expr COMMA A
            | bitop pexpr COMMA A
            | bitop expr COMMA reg8
            | bitop pexpr COMMA reg8
            | bitop expr COMMA reg8_hl
            | bitop pexpr COMMA reg8_hl
    """
    bit = p[2].eval()
    if bit < 0 or bit > 7:
        error(p.lineno(3), 'Invalid bit position %i. Must be in [0..7]' % bit)
        p[0] = None
        return

    p[0] = Asm(p.lineno(3), '%s %i,%s' % (p[1], bit, p[4]))


def p_BIT_ix(p):
    """ asm : bitop expr COMMA reg8_I
            | bitop pexpr COMMA reg8_I
    """
    bit = p[2].eval()
    if bit < 0 or bit > 7:
        error(p.lineno(3), 'Invalid bit position %i. Must be in [0..7]' % bit)
        p[0] = None
        return

    p[0] = Asm(p.lineno(3), '%s %i,%s' % (p[1], bit, p[4][0]), p[4][1])


def p_bitop(p):
    """ bitop : BIT
              | RES
              | SET
    """
    p[0] = p[1]


def p_rotation(p):
    """ rotation : RR
                 | RL
                 | RRC
                 | RLC
                 | SLA
                 | SLL
                 | SRA
                 | SRL
    """
    p[0] = (p[1], p.lineno(1))


def p_reg_inc(p):  # INC/DEC registers and (HL)
    """ inc_reg : SP
                | reg8
                | reg16
                | reg8_hl
                | A
                | reg8i
    """
    p[0] = p[1]


def p_reg8(p):
    """ reg8 : H
             | L
             | regBCDE
    """
    p[0] = p[1]


def p_regBCDE(p):
    """ regBCDE : B
                | C
                | D
                | E
    """
    p[0] = p[1]


def p_reg8i(p):
    """ reg8i : IXH
              | IXL
              | IYH
              | IYL
    """
    p[0] = p[1]


def p_reg16(p):
    """ reg16 : BC
             | DE
             | HL
             | reg16i
    """
    p[0] = p[1]


def p_reg16i(p):
    """ reg16i : IX
               | IY
    """
    p[0] = p[1]


def p_jp(p):
    """ asm : JP jp_flags COMMA expr
            | JP jp_flags COMMA pexpr
            | CALL jp_flags COMMA expr
            | CALL jp_flags COMMA pexpr
    """
    p[0] = Asm(p.lineno(1), '%s %s,NN' % (p[1], p[2]), p[4])


def p_ret(p):
    """ asm : RET jp_flags
    """
    p[0] = Asm(p.lineno(1), 'RET %s' % p[2])


def p_jpflags_other(p):
    """ jp_flags : P
                 | M
                 | PO
                 | PE
                 | jr_flags
    """
    p[0] = p[1]


def p_jr(p):
    """ asm : JR jr_flags COMMA expr
            | JR jr_flags COMMA pexpr
    """
    p[4] = Expr.makenode(Container('-', p.lineno(3)), p[4], Expr.makenode(Container(MEMORY.org + 2, p.lineno(1))))
    p[0] = Asm(p.lineno(1), 'JR %s,N' % p[2], p[4])


def p_jr_flags(p):
    """ jr_flags : Z
                 | C
                 | NZ
                 | NC
    """
    p[0] = p[1]


def p_jrjp(p):
    """ asm : JP expr
            | JR expr
            | CALL expr
            | DJNZ expr
            | JP pexpr
            | JR pexpr
            | CALL pexpr
            | DJNZ pexpr
    """
    if p[1] in ('JR', 'DJNZ'):
        op = 'N'
        p[2] = Expr.makenode(Container('-', p.lineno(1)), p[2], Expr.makenode(Container(MEMORY.org + 2, p.lineno(1))))
    else:
        op = 'NN'

    p[0] = Asm(p.lineno(1), p[1] + ' ' + op, p[2])


def p_rst(p):
    """ asm : RST expr
    """
    val = p[2].eval()

    if val not in (0, 8, 16, 24, 32, 40, 48, 56):
        error(p.lineno(1), 'Invalid RST number %i' % val)
        p[0] = None
        return

    p[0] = Asm(p.lineno(1), 'RST %XH' % val)


def p_im(p):
    """ asm : IM expr
    """
    val = p[2].eval()
    if val not in (0, 1, 2):
        error(p.lineno(1), 'Invalid IM number %i' % val)
        p[0] = None
        return

    p[0] = Asm(p.lineno(1), 'IM %i' % val)


def p_in(p):
    """    asm : IN A COMMA LP C RP
            | IN reg8 COMMA LP C RP
    """
    p[0] = Asm(p.lineno(1), 'IN %s,(C)' % p[2])


def p_out(p):
    """    asm : OUT LP C RP COMMA A
            | OUT LP C RP COMMA reg8
    """
    p[0] = Asm(p.lineno(1), 'OUT (C),%s' % p[6])


def p_in_expr(p):
    """ asm : IN A COMMA pexpr
    """
    p[0] = Asm(p.lineno(1), 'IN A,(N)', p[4])


def p_out_expr(p):
    """ asm : OUT pexpr COMMA A
    """
    p[0] = Asm(p.lineno(1), 'OUT (N),A', p[2])


def p_single(p):
    """ asm : NOP
            | EXX
            | CCF
            | SCF
            | LDIR
            | LDI
            | LDDR
            | LDD
            | CPIR
            | CPI
            | CPDR
            | CPD
            | DAA
            | NEG
            | CPL
            | HALT
            | EI
            | DI
            | OUTD
            | OUTI
            | OTDR
            | OTIR
            | IND
            | INI
            | INDR
            | INIR
            | RET
            | RETI
            | RETN
            | RLA
            | RLCA
            | RRA
            | RRCA
            | RLD
            | RRD
    """
    p[0] = Asm(p.lineno(1), p[1])  # Single instruction


def p_expr_div_expr(p):
    """ expr : expr BAND expr
             | expr BOR expr
             | expr BXOR expr
             | expr PLUS expr
             | expr MINUS expr
             | expr MUL expr
             | expr DIV expr
             | expr MOD expr
             | expr POW expr
             | expr LSHIFT expr
             | expr RSHIFT expr
             | pexpr BAND expr
             | pexpr BOR expr
             | pexpr BXOR expr
             | pexpr PLUS expr
             | pexpr MINUS expr
             | pexpr MUL expr
             | pexpr DIV expr
             | pexpr MOD expr
             | pexpr POW expr
             | pexpr LSHIFT expr
             | pexpr RSHIFT expr
             | expr BAND pexpr
             | expr BOR pexpr
             | expr BXOR pexpr
             | expr PLUS pexpr
             | expr MINUS pexpr
             | expr MUL pexpr
             | expr DIV pexpr
             | expr MOD pexpr
             | expr POW pexpr
             | expr LSHIFT pexpr
             | expr RSHIFT pexpr
             | pexpr BAND pexpr
             | pexpr BOR pexpr
             | pexpr BXOR pexpr
             | pexpr PLUS pexpr
             | pexpr MINUS pexpr
             | pexpr MUL pexpr
             | pexpr DIV pexpr
             | pexpr MOD pexpr
             | pexpr POW pexpr
             | pexpr LSHIFT pexpr
             | pexpr RSHIFT pexpr
    """
    p[0] = Expr.makenode(Container(p[2], p.lineno(2)), p[1], p[3])


def p_expr_lprp(p):
    """ pexpr : LP expr RP
    """
    p[0] = p[2]


def p_expr_uminus(p):
    """ expr : MINUS expr %prec UMINUS
    """
    p[0] = Expr.makenode(Container('-', p.lineno(1)), p[2])


def p_expr_int(p):
    """ expr : INTEGER
    """
    p[0] = Expr.makenode(Container(int(p[1]), p.lineno(1)))


def p_expr_label(p):
    """ expr : ID
    """
    p[0] = Expr.makenode(Container(MEMORY.get_label(p[1], p.lineno(1)), p.lineno(1)))


def p_expr_paren(p):
    """ expr : LPP expr RPP
    """
    p[0] = p[2]


def p_expr_addr(p):
    """ expr : ADDR
    """
    # The current instruction address
    p[0] = Expr.makenode(Container(MEMORY.org, p.lineno(1)))


# Some preprocessor directives
def p_preprocessor_line(p):
    """ line : preproc_line
    """
    p[0] = None


def p_preprocessor_line_line(p):
    """ preproc_line : _LINE INTEGER
    """
    p.lexer.lineno = int(p[2]) + p.lexer.lineno - p.lineno(2)


def p_preprocessor_line_line_file(p):
    """ preproc_line : _LINE INTEGER STRING
    """
    p.lexer.lineno = int(p[2]) + p.lexer.lineno - p.lineno(3) - 1
    gl.FILENAME = p[3]


def p_preproc_line_init(p):
    """ preproc_line : _INIT ID
    """
    INITS.append((p[2], p.lineno(2)))


# --- YYERROR

def p_error(p):
    if p is not None:
        if p.type != 'NEWLINE':
            error(p.lineno, "Syntax error. Unexpected token '%s' [%s]" % (p.value, p.type))
        else:
            error(p.lineno, "Syntax error. Unexpected end of line [NEWLINE]")
    else:
        OPTIONS.stderr.value.write("General syntax error at assembler (unexpected End of File?)")
        gl.has_errors += 1


def assemble(input_):
    """ Assembles input string, and leave the result in the
    MEMORY global object
    """
    global MEMORY

    if MEMORY is None:
        MEMORY = Memory()

    parser.parse(input_, lexer=LEXER, debug=OPTIONS.Debug.value > 2)
    if len(MEMORY.scopes):
        error(MEMORY.scopes[-1], 'Missing ENDP to close this scope')

    return gl.has_errors


def generate_binary(outputfname, format_, progname='', binary_files=None, headless_binary_files=None):
    """ Outputs the memory binary to the
    output filename using one of the given
    formats: tap, tzx or bin
    """
    global AUTORUN_ADDR

    org, binary = MEMORY.dump()
    if gl.has_errors:
        return

    if binary_files is None:
        binary_files = []

    if headless_binary_files is None:
        headless_binary_files = []

    bin_blocks = []
    for fname in binary_files:
        with api.utils.open_file(fname) as f:
            bin_blocks.append((os.path.basename(fname), f.read()))

    headless_bin_blocks = []
    for fname in headless_binary_files:
        with api.utils.open_file(fname) as f:
            headless_bin_blocks.append(f.read())

    if AUTORUN_ADDR is None:
        AUTORUN_ADDR = org

    if not progname:
        progname = os.path.basename(outputfname)[:10]

    if OPTIONS.use_loader.value:
        import basic  # Minimalist basic tokenizer

        program = basic.Basic()
        if org > 16383:  # Only for zx48k: CLEAR if below 16383
            program.add_line([['CLEAR', org - 1]])
        program.add_line([['LOAD', '""', program.token('CODE')]])

        if OPTIONS.autorun.value:
            program.add_line([['RANDOMIZE', program.token('USR'), AUTORUN_ADDR]])
        else:
            program.add_line([['REM'], ['RANDOMIZE', program.token('USR'), AUTORUN_ADDR]])

    if format_ in ('tap', 'tzx'):
        t = {'tap': outfmt.TAP, 'tzx': outfmt.TZX}[format_]()

        if OPTIONS.use_loader.value:
            t.save_program('loader', program.bytes, line=1)  # Put line 0 to protect against MERGE

        t.save_code(progname, org, binary)
        for name, block in bin_blocks:
            t.save_code(name, 0, block)
        for block in headless_bin_blocks:
            t.standard_block(block)

        t.dump(outputfname)

    else:
        with open(outputfname, 'wb') as f:
            f.write(bytearray(binary))


def main(argv):
    """ This is a test and will assemble the file in argv[0]
    """
    init()

    if OPTIONS.StdErrFileName.value:
        OPTIONS.stderr.value = open('wt', OPTIONS.StdErrFileName.value)

    asmlex.FILENAME = OPTIONS.inputFileName.value = argv[0]
    input_ = open(OPTIONS.inputFileName.value, 'rt').read()
    assemble(input_)
    generate_binary(OPTIONS.outputFileName.value, OPTIONS.output_file_type)


parser = yacc.yacc(method='LALR', tabmodule='parsetab.zxbasmtab', debug=OPTIONS.Debug.value > 2)
