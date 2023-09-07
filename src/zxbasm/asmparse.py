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
from typing import Optional

import src.api.utils
import src.ply.yacc as yacc
from src import outfmt
from src.api import global_ as gl
from src.api.config import OPTIONS
from src.api.debug import __DEBUG__
from src.api.errmsg import error, warning
from src.zxbasm import asmlex, basic
from src.zxbasm import global_ as asm_gl
from src.zxbasm.asm import Asm, Container
from src.zxbasm.asmlex import tokens  # noqa
from src.zxbasm.expr import Expr
from src.zxbasm.global_ import DOT
from src.zxbasm.memory import Memory
from src.zxbpp import zxbpp

LEXER = asmlex.Lexer()

ORG = 0  # Origin of CODE
INITS = []
MEMORY: Optional[Memory] = None  # Memory for instructions (Will be initialized with a Memory() instance)
AUTORUN_ADDR = None  # Where to start the execution automatically

REGS16 = {"BC", "DE", "HL", "SP", "IX", "IY"}  # 16 Bits registers

precedence = (
    ("left", "RSHIFT", "LSHIFT", "BAND", "BOR", "BXOR"),
    ("left", "PLUS", "MINUS"),
    ("left", "MUL", "DIV", "MOD"),
    ("right", "POW"),
    ("right", "UMINUS"),
)


def init():
    """Initializes this module"""
    global ORG
    global LEXER
    global MEMORY
    global INITS
    global AUTORUN_ADDR

    ORG = 0  # Origin of CODE
    INITS = []
    MEMORY = None  # Memory for instructions (Will be initialized with a Memory() instance)
    AUTORUN_ADDR = None  # Where to start the execution automatically
    gl.has_errors = 0
    gl.error_msg_cache.clear()

    # Current namespace (defaults to ''). It's a prefix added to each global label
    asm_gl.NAMESPACE = asm_gl.GLOBAL_NAMESPACE


# -------- GRAMMAR RULES for the preprocessor ---------


def p_start(p):
    """start : program
    | program endline
    """


def p_program_endline(p):
    """endline : END NEWLINE"""


def p_program_endline2(p):
    """endline : END expr NEWLINE
    | END pexpr NEWLINE
    """
    global AUTORUN_ADDR
    AUTORUN_ADDR = p[2].eval()


def p_program(p):
    """program : line"""


def p_program_line(p):
    """program : program line"""


def p_def_label(p):
    """line : ID EQU expr NEWLINE
    | ID EQU pexpr NEWLINE
    """
    p[0] = None
    MEMORY.declare_label(p[1], p.lineno(1), p[3])


def p_line_asm(p):
    """line : asms NEWLINE
    | asms CO NEWLINE
    """


def p_asms_empty(p):
    """asms :"""
    p[0] = MEMORY.org


def p_asms_asm(p):
    """asms : asm"""
    p[0] = MEMORY.org
    asm = p[1]
    if isinstance(asm, Asm):
        MEMORY.add_instruction(asm)


def p_asms_asms_asm(p):
    """asms : asms CO asm"""
    p[0] = p[1]
    asm = p[3]
    if isinstance(asm, Asm):
        MEMORY.add_instruction(asm)


def p_asm_label(p):
    """asm : ID
    | INTEGER
    """
    MEMORY.declare_label(str(p[1]), p.lineno(1))


def p_asm_ld8(p):
    """asm : LD reg8 COMMA reg8_hl
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
    if p[2] in ("H", "L") and p[4] in ("IXH", "IXL", "IYH", "IYL"):
        p[0] = None
        error(p.lineno(0), "Unexpected token '%s'" % p[4])
    else:
        p[0] = Asm(p.lineno(1), "LD %s,%s" % (p[2], p[4]))


def p_LDa(p):  # Remaining LD A,... and LD...,A instructions
    """asm : LD A COMMA LP BC RP
    | LD A COMMA LB BC RB
    | LD A COMMA LP DE RP
    | LD A COMMA LB DE RB
    | LD LP BC RP COMMA A
    | LD LB BC RB COMMA A
    | LD LP DE RP COMMA A
    | LD LB DE RB COMMA A
    """
    p[0] = Asm(p.lineno(1), "LD " + "".join(x.replace("[", "(").replace("]", ")") for x in p[2:]))


def p_PROC(p):
    """asm : PROC"""
    p[0] = None  # Start of a PROC scope
    MEMORY.enter_proc(p.lineno(1))


def p_ENDP(p):
    """asm : ENDP"""
    p[0] = None  # End of a PROC scope
    MEMORY.exit_proc(p.lineno(1))


def p_LOCAL(p):
    """asm : LOCAL id_list"""
    p[0] = None
    for label, line in p[2]:
        __DEBUG__("Setting label '%s' as local at line %i" % (label, line))

        MEMORY.set_label(label, line, local=True)


def p_idlist(p):
    """id_list : ID"""
    p[0] = (Container(p[1], p.lineno(1)),)


def p_idlist_id(p):
    """id_list : id_list COMMA ID"""
    p[0] = p[1] + (Container(p[3], p.lineno(3)),)


def p_DEFB(p):  # Define bytes
    """asm : DEFB expr_list"""
    p[0] = Asm(p.lineno(1), "DEFB", p[2])


def p_DEFS(p):  # Define bytes
    """asm : DEFS number_list"""
    if len(p[2]) > 2:
        error(p.lineno(1), "too many arguments for DEFS")

    if len(p[2]) < 2:
        num = Expr.makenode(Container(0, p.lineno(1)))  # Defaults to 0
        p[2] = p[2] + (num,)

    p[0] = Asm(p.lineno(1), "DEFS", p[2])


def p_DEFW(p):  # Define words
    """asm : DEFW number_list"""
    p[0] = Asm(p.lineno(1), "DEFW", p[2])


def p_expr_list_from_string(p):
    """expr_list : STRING"""
    p[0] = tuple(Expr.makenode(Container(ord(x), p.lineno(1))) for x in p[1])


def p_expr_list_from_num(p):
    """expr_list : expr
    | pexpr
    """
    p[0] = (p[1],)


def p_expr_list_plus_expr(p):
    """expr_list : expr_list COMMA expr
    | expr_list COMMA pexpr
    """
    p[0] = p[1] + (p[3],)


def p_expr_list_plus_string(p):
    """expr_list : expr_list COMMA STRING"""
    p[0] = p[1] + tuple(Expr.makenode(Container(ord(x), p.lineno(3))) for x in p[3])


def p_number_list(p):
    """number_list : expr
    | pexpr
    """
    p[0] = (p[1],)


def p_number_list_number(p):
    """number_list : number_list COMMA expr
    | number_list COMMA pexpr
    """
    p[0] = p[1] + (p[3],)


def p_asm_ldind_r8(p):
    """asm : LD reg8_I COMMA reg8
    | LD reg8_I COMMA A
    """
    p[0] = Asm(p.lineno(1), "LD %s,%s" % (p[2][0], p[4]), p[2][1])


def p_asm_ldr8_ind(p):
    """asm : LD reg8 COMMA reg8_I
    | LD A COMMA reg8_I
    """
    p[0] = Asm(p.lineno(1), "LD %s,%s" % (p[2], p[4][0]), p[4][1])


def p_reg8_hl(p):
    """reg8_hl : LP HL RP
    | LB HL RB
    """
    p[0] = "(HL)"


def p_ind8_I(p):
    """reg8_I : LP IX expr RP
    | LP IY expr RP
    | LP IX PLUS pexpr RP
    | LP IX MINUS pexpr RP
    | LP IY PLUS pexpr RP
    | LP IY MINUS pexpr RP
    | LB IX expr RB
    | LB IY expr RB
    | LB IX PLUS pexpr RB
    | LB IX MINUS pexpr RB
    | LB IY PLUS pexpr RB
    | LB IY MINUS pexpr RB
    """
    if len(p) == 6:
        expr = p[4]
        sign = p[3]
    else:
        expr = p[3]
        gen_ = expr.inorder()
        first_expr = next(gen_, "")
        if first_expr and first_expr.parent:
            if len(first_expr.parent.children) == 2:
                first_token = first_expr.symbol.item
            else:
                first_token = first_expr.parent.symbol.item
        else:
            first_token = "<nothing>"
        if first_token not in ("-", "+"):
            error(p.lineno(2), "Unexpected token '{}'. Expected '+' or '-'".format(first_token))
        sign = "+"

    if sign == "-":
        expr = Expr.makenode(Container(sign, p.lineno(2)), expr)

    p[0] = ("(%s+N)" % p[2], expr)


def p_ex_af_af(p):
    """asm : EX AF COMMA AF APO"""
    p[0] = Asm(p.lineno(1), "EX AF,AF'")


def p_ex_de_hl(p):
    """asm : EX DE COMMA HL"""
    p[0] = Asm(p.lineno(1), "EX DE,HL")


def p_org(p):
    """asm : ORG expr
    | ORG pexpr
    """
    MEMORY.set_org(p[2].eval(), p.lineno(1))


def p_namespace(p):
    """asm : NAMESPACE ID"""

    asm_gl.NAMESPACE = asm_gl.normalize_namespace(p[2])
    __DEBUG__("Setting namespace to " + (asm_gl.NAMESPACE or DOT), level=1)


def p_push_namespace(p):
    """asm : PUSH NAMESPACE
    | PUSH NAMESPACE ID
    """

    asm_gl.NAMESPACE_STACK.append(asm_gl.NAMESPACE)
    asm_gl.NAMESPACE = asm_gl.normalize_namespace(p[3] if len(p) == 4 else asm_gl.NAMESPACE)

    if asm_gl.NAMESPACE != asm_gl.NAMESPACE_STACK[-1]:
        __DEBUG__("Setting namespace to " + (asm_gl.NAMESPACE or DOT), level=1)


def p_pop_namespace(p):
    """asm : POP NAMESPACE"""

    if not asm_gl.NAMESPACE_STACK:
        error(p.lineno(2), f"Stack underflow. No more Namespaces to pop. Current namespace is {asm_gl.NAMESPACE}")
    else:
        asm_gl.NAMESPACE = asm_gl.NAMESPACE_STACK.pop()


def p_align(p):
    """asm : ALIGN expr
    | ALIGN pexpr
    """
    align = p[2].eval()
    if align < 2:
        error(p.lineno(1), "ALIGN value must be greater than 1")
        return

    MEMORY.set_org(MEMORY.org + (align - MEMORY.org % align) % align, p.lineno(1))


def p_incbin(p):
    """asm : INCBIN STRING
    | INCBIN STRING COMMA expr
    | INCBIN STRING COMMA expr COMMA expr
    """

    try:
        fname = zxbpp.search_filename(p[2], p.lineno(2), local_first=True)
        if not fname:
            p[0] = None
            return

        with src.api.utils.open_file(fname, "rb") as f:
            filecontent = f.read()

    except IOError:
        error(p.lineno(2), "cannot read file '%s'" % p[2])
        p[0] = None
        return

    offset = 0
    length = None

    if len(p) > 4:
        offset = p[4].eval()

    if len(p) > 6:
        length = p[6].eval()
        if length < 1:
            error(p.lineno(5), "INCBIN length must be greater than 0")

    if offset < 0:
        offset = len(filecontent) + offset
        if offset < 0 or offset >= len(filecontent):
            error(p.lineno(4), "INCBIN offset is out of range")

    if length is None:
        length = len(filecontent) - offset

    if offset + length > len(filecontent):
        excess = len(filecontent) - (offset + length)
        warning(p.lineno(5), f"INCBIN length if beyond file length by {excess} bytes")

    filecontent = filecontent[offset : offset + length]
    p[0] = Asm(p.lineno(1), "DEFB", filecontent)


def p_ex_sp_reg8(p):
    """asm : EX LP SP RP COMMA reg16i
    | EX LB SP RB COMMA reg16i
    | EX LP SP RP COMMA HL
    | EX LB SP RB COMMA HL
    """
    p[0] = Asm(p.lineno(1), "EX (SP)," + p[6])


def p_incdec(p):
    """asm : INC inc_reg
    | DEC inc_reg
    """
    p[0] = Asm(p.lineno(1), "%s %s" % (p[1], p[2]))


def p_incdeci(p):
    """asm : INC reg8_I
    | DEC reg8_I
    """
    p[0] = Asm(p.lineno(1), "%s %s" % (p[1], p[2][0]), p[2][1])


def p_LD_reg_val(p):
    """asm : LD reg8 COMMA expr
    | LD reg8 COMMA pexpr
    | LD reg16 COMMA expr
    | LD reg8_hl COMMA expr
    | LD A COMMA expr
    | LD SP COMMA expr
    | LD reg8i COMMA expr
    """
    s = "LD %s,N" % p[2]
    if p[2] in REGS16:
        s += "N"

    p[0] = Asm(p.lineno(1), s, p[4])


def p_LD_regI_val(p):
    """asm : LD reg8_I COMMA expr"""
    p[0] = Asm(p.lineno(1), "LD %s,N" % p[2][0], (p[2][1], p[4]))


def p_JP_hl(p):
    """asm : JP reg8_hl
    | JP LP reg16i RP
    | JP LB reg16i RB
    """
    s = "JP "
    if p[2] == "(HL)":
        s += p[2]
    else:
        s += "(%s)" % p[3]

    p[0] = Asm(p.lineno(1), s)


def p_SBCADD(p):
    """asm : SBC A COMMA reg8
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
    p[0] = Asm(p.lineno(1), "%s %s,%s" % (p[1], p[2], p[4]))


def p_arith_A_expr(p):
    """asm : SBC A COMMA expr
    | SBC A COMMA pexpr
    | ADD A COMMA expr
    | ADD A COMMA pexpr
    | ADC A COMMA expr
    | ADC A COMMA pexpr
    """
    p[0] = Asm(p.lineno(1), "%s A,N" % p[1], p[4])


def p_arith_A_regI(p):
    """asm : SBC A COMMA reg8_I
    | ADD A COMMA reg8_I
    | ADC A COMMA reg8_I
    """
    p[0] = Asm(p.lineno(1), "%s A,%s" % (p[1], p[4][0]), p[4][1])


def p_bitwiseop_reg(p):
    """asm : bitwiseop reg8
    | bitwiseop reg8i
    | bitwiseop A
    | bitwiseop reg8_hl
    """
    p[0] = Asm(p[1][1], "%s %s" % (p[1][0], p[2]))


def p_bitwiseop_regI(p):
    """asm : bitwiseop reg8_I"""
    p[0] = Asm(p[1][1], "%s %s" % (p[1][0], p[2][0]), p[2][1])


def p_bitwise_expr(p):
    """asm : bitwiseop expr
    | bitwiseop pexpr
    """
    p[0] = Asm(p[1][1], "%s N" % p[1][0], p[2])


def p_bitwise(p):
    """bitwiseop : OR
    | AND
    | XOR
    | SUB
    | CP
    """
    p[0] = (p[1], p.lineno(1))


def p_PUSH_POP(p):
    """asm : PUSH AF
    | PUSH reg16
    | POP AF
    | POP reg16
    """
    p[0] = Asm(p.lineno(1), "%s %s" % (p[1], p[2]))


def p_LD_addr_reg(p):  # Load address,reg
    """asm : LD pexpr COMMA A
    | LD pexpr COMMA reg16
    | LD pexpr COMMA SP
    | LD mem_indir COMMA A
    | LD mem_indir COMMA reg16
    | LD mem_indir COMMA SP
    """
    p[0] = Asm(p.lineno(1), "LD (NN),%s" % p[4], p[2])


def p_LD_reg_addr(p):  # Load address,reg
    """asm : LD A COMMA pexpr
    | LD reg16 COMMA pexpr
    | LD SP COMMA pexpr
    | LD A COMMA mem_indir
    | LD reg16 COMMA mem_indir
    | LD SP COMMA mem_indir
    """
    p[0] = Asm(p.lineno(1), "LD %s,(NN)" % p[2], p[4])


def p_ROTATE(p):
    """asm : rotation reg8
    | rotation reg8_hl
    | rotation A
    """
    p[0] = Asm(p[1][1], "%s %s" % (p[1][0], p[2]))


def p_ROTATE_ix(p):
    """asm : rotation reg8_I"""
    p[0] = Asm(p[1][1], "%s %s" % (p[1][0], p[2][0]), p[2][1])


def p_BIT(p):
    """asm : bitop expr COMMA A
    | bitop pexpr COMMA A
    | bitop expr COMMA reg8
    | bitop pexpr COMMA reg8
    | bitop expr COMMA reg8_hl
    | bitop pexpr COMMA reg8_hl
    """
    bit = p[2].eval()
    if bit < 0 or bit > 7:
        error(p.lineno(3), "Invalid bit position %i. Must be in [0..7]" % bit)
        p[0] = None
        return

    p[0] = Asm(p.lineno(3), "%s %i,%s" % (p[1], bit, p[4]))


def p_BIT_ix(p):
    """asm : bitop expr COMMA reg8_I
    | bitop pexpr COMMA reg8_I
    """
    bit = p[2].eval()
    if bit < 0 or bit > 7:
        error(p.lineno(3), "Invalid bit position %i. Must be in [0..7]" % bit)
        p[0] = None
        return

    p[0] = Asm(p.lineno(3), "%s %i,%s" % (p[1], bit, p[4][0]), p[4][1])


def p_bitop(p):
    """bitop : BIT
    | RES
    | SET
    """
    p[0] = p[1]


def p_rotation(p):
    """rotation : RR
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
    """inc_reg : SP
    | reg8
    | reg16
    | reg8_hl
    | A
    | reg8i
    """
    p[0] = p[1]


def p_reg8(p):
    """reg8 : H
    | L
    | regBCDE
    """
    p[0] = p[1]


def p_regBCDE(p):
    """regBCDE : B
    | C
    | D
    | E
    """
    p[0] = p[1]


def p_reg8i(p):
    """reg8i : IXH
    | IXL
    | IYH
    | IYL
    """
    p[0] = p[1]


def p_reg16(p):
    """reg16 : BC
    | DE
    | HL
    | reg16i
    """
    p[0] = p[1]


def p_reg16i(p):
    """reg16i : IX
    | IY
    """
    p[0] = p[1]


def p_jp(p):
    """asm : JP jp_flags COMMA expr
    | JP jp_flags COMMA pexpr
    | CALL jp_flags COMMA expr
    | CALL jp_flags COMMA pexpr
    """
    p[0] = Asm(p.lineno(1), "%s %s,NN" % (p[1], p[2]), p[4])


def p_ret(p):
    """asm : RET jp_flags"""
    p[0] = Asm(p.lineno(1), "RET %s" % p[2])


def p_jpflags_other(p):
    """jp_flags : P
    | M
    | PO
    | PE
    | jr_flags
    """
    p[0] = p[1]


def p_jr(p):
    """asm : JR jr_flags COMMA expr
    | JR jr_flags COMMA pexpr
    """
    p[4] = Expr.makenode(Container("-", p.lineno(3)), p[4], Expr.makenode(Container(MEMORY.org + 2, p.lineno(1))))
    p[0] = Asm(p.lineno(1), "JR %s,N" % p[2], p[4])


def p_jr_flags(p):
    """jr_flags : Z
    | C
    | NZ
    | NC
    """
    p[0] = p[1]


def p_jrjp(p):
    """asm : JP expr
    | JR expr
    | CALL expr
    | DJNZ expr
    | JP pexpr
    | JR pexpr
    | CALL pexpr
    | DJNZ pexpr
    """
    if p[1] in ("JR", "DJNZ"):
        op = "N"
        p[2] = Expr.makenode(Container("-", p.lineno(1)), p[2], Expr.makenode(Container(MEMORY.org + 2, p.lineno(1))))
    else:
        op = "NN"

    p[0] = Asm(p.lineno(1), p[1] + " " + op, p[2])


def p_rst(p):
    """asm : RST expr"""
    val = p[2].eval()

    if val not in (0, 8, 16, 24, 32, 40, 48, 56):
        error(p.lineno(1), "Invalid RST number %i" % val)
        p[0] = None
        return

    p[0] = Asm(p.lineno(1), "RST %XH" % val)


def p_im(p):
    """asm : IM expr"""
    val = p[2].eval()
    if val not in (0, 1, 2):
        error(p.lineno(1), "Invalid IM number %i" % val)
        p[0] = None
        return

    p[0] = Asm(p.lineno(1), "IM %i" % val)


def p_in(p):
    """asm : IN A COMMA LP C RP
    | IN A COMMA LB C RB
    | IN reg8 COMMA LP C RP
    | IN reg8 COMMA LB C RB
    """
    p[0] = Asm(p.lineno(1), "IN %s,(C)" % p[2])


def p_out(p):
    """asm : OUT LP C RP COMMA A
    | OUT LB C RB COMMA A
    | OUT LP C RP COMMA reg8
    | OUT LB C RB COMMA reg8
    """
    p[0] = Asm(p.lineno(1), "OUT (C),%s" % p[6])


def p_in_expr(p):
    """asm : IN A COMMA mem_indir
    | IN A COMMA pexpr
    """
    p[0] = Asm(p.lineno(1), "IN A,(N)", p[4])


def p_out_expr(p):
    """asm : OUT mem_indir COMMA A
    | OUT pexpr COMMA A
    """
    p[0] = Asm(p.lineno(1), "OUT (N),A", p[2])


def p_single(p):
    """asm : NOP
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
    """expr : expr BAND expr
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
    """pexpr : LP expr RP"""
    p[0] = p[2]


def p_mem_indir(p):
    """mem_indir : LB expr RB"""
    p[0] = p[2]


def p_expr_uminus(p):
    """expr : MINUS expr %prec UMINUS
    | PLUS expr %prec UMINUS
    | MINUS pexpr %prec UMINUS
    | PLUS pexpr %prec UMINUS
    """
    p[0] = Expr.makenode(Container(p[1], p.lineno(1)), p[2])


def p_expr_int(p):
    """expr : INTEGER"""
    p[0] = Expr.makenode(Container(int(p[1]), p.lineno(1)))


def p_expr_label(p):
    """expr : ID"""
    p[0] = Expr.makenode(Container(MEMORY.get_label(p[1], p.lineno(1)), p.lineno(1)))


def p_expr_paren(p):
    """expr : LPP expr RPP"""
    p[0] = p[2]


def p_expr_addr(p):
    """expr : ADDR"""
    # The current instruction address
    p[0] = Expr.makenode(Container(MEMORY.org, p.lineno(1)))


# Some preprocessor directives
def p_preprocessor_line(p):
    """line : preproc_line"""
    p[0] = None


def p_preproc_line_init(p):
    """preproc_line : _INIT STRING"""
    INITS.append(Container(p[2].strip('"'), p.lineno(2)))


# --- YYERROR


def p_error(p):
    if p is not None:
        if p.type != "NEWLINE":
            error(p.lineno, "Syntax error. Unexpected token '%s' [%s]" % (p.value, p.type))
        else:
            error(p.lineno, "Syntax error. Unexpected end of line [NEWLINE]")
    else:
        OPTIONS.stderr.write("General syntax error at assembler (unexpected End of File?)")
        gl.has_errors += 1


def assemble(input_):
    """Assembles input string, and leave the result in the
    MEMORY global object
    """
    global MEMORY

    if MEMORY is None:
        MEMORY = Memory()

    if OPTIONS.zxnext:
        parser_ = zxnext_parser
    else:
        parser_ = parser

    parser_.parse(input_, lexer=LEXER, debug=OPTIONS.debug_level > 1)
    if len(MEMORY.scopes):
        error(MEMORY.scopes[-1], "Missing ENDP to close this scope")

    return gl.has_errors


def generate_binary(outputfname, format_, progname="", binary_files=None, headless_binary_files=None, emitter=None):
    """Outputs the memory binary to the
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
        with src.api.utils.open_file(fname) as f:
            bin_blocks.append((os.path.basename(fname), f.read()))

    headless_bin_blocks = []
    for fname in headless_binary_files:
        with src.api.utils.open_file(fname) as f:
            headless_bin_blocks.append(f.read())

    if AUTORUN_ADDR is None:
        AUTORUN_ADDR = org

    if not progname:
        progname = os.path.basename(outputfname)[:10]

    loader_bytes = None

    if OPTIONS.use_basic_loader:
        program = basic.Basic()
        if org > 16383:  # Only for zx48k: CLEAR if above 16383
            program.add_line([["CLEAR", org - 1]])
        program.add_line([["LOAD", '""', program.token("CODE")]])

        if OPTIONS.autorun:
            program.add_line([["RANDOMIZE", program.token("USR"), AUTORUN_ADDR]])
        else:
            program.add_line([["REM"], ["RANDOMIZE", program.token("USR"), AUTORUN_ADDR]])

        loader_bytes = program.bytes

    if emitter is None:
        if format_ in ("tap", "tzx"):
            emitter = {"tap": outfmt.TAP, "tzx": outfmt.TZX}[format_]()
        else:
            emitter = outfmt.BinaryEmitter()

    assert isinstance(emitter, outfmt.CodeEmitter)
    emitter.emit(
        output_filename=outputfname,
        program_name=progname,
        loader_bytes=loader_bytes,
        entry_point=AUTORUN_ADDR,
        program_bytes=binary,
        aux_bin_blocks=bin_blocks,
        aux_headless_bin_blocks=headless_bin_blocks,
    )


def main(argv):
    """This is a test and will assemble the file in argv[0]"""
    init()

    if OPTIONS.stderr_filename:
        OPTIONS.stderr = open("wt", OPTIONS.stderr_filename)

    asmlex.FILENAME = OPTIONS.input_filename = argv[0]
    input_ = open(OPTIONS.input_filename, "rt").read()
    assemble(input_)
    generate_binary(OPTIONS.output_filename, OPTIONS.output_file_type)


# Z80 only ASM parser
parser = src.api.utils.get_or_create("asmparse", lambda: yacc.yacc(start="start", debug=True))

# needed for ply
from .zxnext import *  # noqa

# ZXNEXT extended Opcodes parser
zxnext_parser = src.api.utils.get_or_create("zxnext_asmparse", lambda: yacc.yacc(start="start", debug=True))
