# -*- coding: utf-8 -*-

__all__ = [
    "p_mul_d_e",
    "p_simple_instruction",
    "p_add_reg16_a",
    "p_JP_c",
    "p_bxxxx_de_b",
    "p_add_reg_NN",
    "p_test_nn",
    "p_nextreg_expr",
    "p_nextreg_a",
    "p_push_imm",
]

from src.zxbasm import asmparse
from src.zxbasm.expr import Expr


def p_mul_d_e(p):
    """asm : MUL D COMMA E"""
    p[0] = asmparse.Asm(p.lineno(1), "MUL D,E")


def p_simple_instruction(p):
    """asm : LDIX
    | LDWS
    | LDIRX
    | LDDX
    | LDDRX
    | LDPIRX
    | OUTINB
    | SWAPNIB
    | MIRROR
    | PIXELDN
    | PIXELAD
    | SETAE
    """
    p[0] = asmparse.Asm(p.lineno(1), p[1])


def p_add_reg16_a(p):
    """asm : ADD HL COMMA A
    | ADD DE COMMA A
    | ADD BC COMMA A
    """
    p[0] = asmparse.Asm(p.lineno(1), "ADD {},A".format(p[2]))


def p_JP_c(p):
    """asm : JP LP C RP
    | JP LB C RB
    """
    p[0] = asmparse.Asm(p.lineno(1), "JP (C)")


def p_bxxxx_de_b(p):
    """asm : BSLA DE COMMA B
    | BSRA DE COMMA B
    | BSRL DE COMMA B
    | BSRF DE COMMA B
    | BRLC DE COMMA B
    """
    p[0] = asmparse.Asm(p.lineno(1), "{} DE,B".format(p[1]))


def p_add_reg_NN(p):
    """asm : ADD HL COMMA expr
    | ADD DE COMMA expr
    | ADD BC COMMA expr
    | ADD HL COMMA pexpr
    | ADD DE COMMA pexpr
    | ADD BC COMMA pexpr
    """
    p[0] = asmparse.Asm(p.lineno(1), "ADD {},NN".format(p[2]), p[4])


def p_test_nn(p):
    """asm : TEST expr
    | TEST pexpr
    """
    p[0] = asmparse.Asm(p.lineno(1), "TEST N", p[2])


def p_nextreg_expr(p):
    """asm : NEXTREG expr COMMA expr
    | NEXTREG expr COMMA pexpr
    | NEXTREG pexpr COMMA expr
    | NEXTREG pexpr COMMA pexpr
    """
    p[0] = asmparse.Asm(p.lineno(1), "NEXTREG N,N", (p[2], p[4]))


def p_nextreg_a(p):
    """asm : NEXTREG expr COMMA A
    | NEXTREG pexpr COMMA A
    """
    p[0] = asmparse.Asm(p.lineno(1), "NEXTREG N,A", p[2])


def p_push_imm(p):
    """asm : PUSH expr
    | PUSH pexpr
    """
    # Reverse HI | LO => X1 = (X0 & 0xFF) << 8 | (X0 >> 8) & 0xFF
    mknod = Expr.makenode
    cont = lambda x: asmparse.Container(x, p.lineno(1))
    ff = mknod(cont(0xFF))
    n8 = mknod(cont(8))

    expr = mknod(
        cont("|"), mknod(cont("<<"), mknod(cont("&"), p[2], ff), n8), mknod(cont("&"), mknod(cont(">>"), p[2], n8), ff)
    )
    p[0] = asmparse.Asm(p.lineno(1), "PUSH NN", expr)
