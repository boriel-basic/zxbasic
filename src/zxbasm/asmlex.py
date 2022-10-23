#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:ts=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Lexer for the zxbasm (ZXBasic Assembler)
# ----------------------------------------------------------------------

import sys
from typing import Tuple

from src.api import global_
from src.api.config import OPTIONS
from src.api.errmsg import error
from src.ply import lex

_tokens: Tuple[str, ...] = (
    "STRING",
    "NEWLINE",
    "CO",
    "ID",
    "COMMA",
    "PLUS",
    "MINUS",
    "LB",
    "RB",
    "LP",
    "RP",
    "LPP",
    "RPP",
    "MUL",
    "DIV",
    "POW",
    "MOD",
    "UMINUS",
    "APO",
    "INTEGER",
    "ADDR",
    "LSHIFT",
    "RSHIFT",
    "BAND",
    "BOR",
    "BXOR",
)

reserved_instructions = {
    "adc": "ADC",
    "add": "ADD",
    "and": "AND",
    "bit": "BIT",
    "call": "CALL",
    "ccf": "CCF",
    "cp": "CP",
    "cpd": "CPD",
    "cpdr": "CPDR",
    "cpi": "CPI",
    "cpir": "CPIR",
    "cpl": "CPL",
    "daa": "DAA",
    "dec": "DEC",
    "di": "DI",
    "djnz": "DJNZ",
    "ei": "EI",
    "ex": "EX",
    "exx": "EXX",
    "halt": "HALT",
    "im": "IM",
    "in": "IN",
    "inc": "INC",
    "ind": "IND",
    "indr": "INDR",
    "ini": "INI",
    "inir": "INIR",
    "jp": "JP",
    "jr": "JR",
    "ld": "LD",
    "ldd": "LDD",
    "lddr": "LDDR",
    "ldi": "LDI",
    "ldir": "LDIR",
    "neg": "NEG",
    "nop": "NOP",
    "or": "OR",
    "otdr": "OTDR",
    "otir": "OTIR",
    "out": "OUT",
    "outd": "OUTD",
    "outi": "OUTI",
    "pop": "POP",
    "push": "PUSH",
    "res": "RES",
    "ret": "RET",
    "reti": "RETI",
    "retn": "RETN",
    "rl": "RL",
    "rla": "RLA",
    "rlc": "RLC",
    "rlca": "RLCA",
    "rld": "RLD",
    "rr": "RR",
    "rra": "RRA",
    "rrc": "RRC",
    "rrca": "RRCA",
    "rrd": "RRD",
    "rst": "RST",
    "sbc": "SBC",
    "scf": "SCF",
    "set": "SET",
    "sla": "SLA",
    "sll": "SLL",
    "sra": "SRA",
    "srl": "SRL",
    "sub": "SUB",
    "xor": "XOR",
}

zx_next_mnemonics = {
    x.lower(): x
    for x in [
        "LDIX",
        "LDWS",
        "LDIRX",
        "LDDX",
        "LDDRX",
        "LDPIRX",
        "OUTINB",
        "MUL",
        "SWAPNIB",
        "MIRROR",
        "NEXTREG",
        "PIXELDN",
        "PIXELAD",
        "SETAE",
        "TEST",
        "BSLA",
        "BSRA",
        "BSRL",
        "BSRF",
        "BRLC",
    ]
}

pseudo = {  # pseudo ops
    "align": "ALIGN",
    "org": "ORG",
    "defb": "DEFB",
    "defm": "DEFB",
    "db": "DEFB",
    "defs": "DEFS",
    "defw": "DEFW",
    "ds": "DEFS",
    "dw": "DEFW",
    "equ": "EQU",
    "proc": "PROC",
    "endp": "ENDP",
    "local": "LOCAL",
    "end": "END",
    "incbin": "INCBIN",
    "namespace": "NAMESPACE",
}

regs8 = {
    "a": "A",
    "b": "B",
    "c": "C",
    "d": "D",
    "e": "E",
    "h": "H",
    "l": "L",
    "i": "I",
    "r": "R",
    "ixh": "IXH",
    "ixl": "IXL",
    "iyh": "IYH",
    "iyl": "IYL",
}

regs16 = {"af": "AF", "bc": "BC", "de": "DE", "hl": "HL", "ix": "IX", "iy": "IY", "sp": "SP"}

flags = {
    "z": "Z",
    "nz": "NZ",
    "nc": "NC",
    "po": "PO",
    "pe": "PE",
    "p": "P",
    "m": "M",
}

preprocessor = {"init": "_INIT"}

# List of token names.
_tokens = tuple(
    sorted(
        _tokens
        + tuple(reserved_instructions.values())
        + tuple(pseudo.values())
        + tuple(regs8.values())
        + tuple(regs16.values())
        + tuple(flags.values())
        + tuple(zx_next_mnemonics.values())
        + tuple(preprocessor.values())
    )
)

keywords = (
    set(flags.keys())
    .union(regs16.keys())
    .union(regs8.keys())
    .union(pseudo.keys())
    .union(reserved_instructions.keys())
    .union(zx_next_mnemonics.keys())
)


def get_uniques(l):
    """Returns a list with no repeated elements."""
    result = []

    for i in l:
        if i not in result:
            result.append(i)

    return result


tokens = get_uniques(_tokens)


class Lexer(object):
    """Own class lexer to allow multiple instances.
    This lexer is just a wrapper of the current FILESTACK[-1] lexer
    """

    states = (("preproc", "exclusive"),)

    # -------------- TOKEN ACTIONS --------------

    @property
    def lineno(self) -> int:
        """Getter for lexer.lineno"""
        return 0 if self.lex is None else self.lex.lineno

    @lineno.setter
    def lineno(self, value: int):
        """Setter for lexer.lineno"""
        self.lex.lineno = value

    def t_INITIAL_preproc_skip(self, t):
        r"[ \t]+"
        pass  # Ignore whitespaces and tabs

    def t_CHAR(self, t):
        r"'.'"  # A single char

        t.value = ord(t.value[1])
        t.type = "INTEGER"
        return t

    def t_HEXA(self, t):
        r"([0-9](_?[0-9a-fA-F])*[hH])|(\$[0-9a-fA-F](_?[0-9a-fA-F])*)|(0x[0-9a-fA-F](_?[0-9a-dA-F])*)"

        if t.value[:2] == "0x":
            t.value = t.value[2:]  # Remove initial 0x
        elif t.value[0] == "$":
            t.value = t.value[1:]  # Remove initial '$'
        else:
            t.value = t.value[:-1]  # Remove last 'h'

        t.value = int(t.value.replace("_", ""), 16)  # Convert to decimal
        t.type = "INTEGER"
        return t

    def t_BIN(self, t):
        r"(%[01](_?[01])*)|(0[bB](_?[01])+)"  # A Binary integer
        # Note 00B is a 0 binary, but
        # 00Bh is a 12 in hex. So this pattern must come
        # after HEXA

        if t.value[0] == "%":
            t.value = t.value[1:]  # Remove initial %
        else:
            t.value = t.value[2:]  # Remove last 'b'

        t.value = int(t.value.replace("_", ""), 2)  # Convert to decimal
        t.type = "INTEGER"
        return t

    def t_INITIAL_TMPLABEL(self, t):
        r"[0-9]+[FfBb]"
        t.type = "ID"
        t.value = t.value.upper()
        return t

    def t_INITIAL_preproc_INTEGER(self, t):
        r"[0-9](_?\d)*"  # an integer decimal number
        t.value = int(t.value.replace("_", ""))
        return t

    def t_INITIAL_ID(self, t):
        r"[._a-zA-Z][._a-zA-Z0-9]*"  # Any identifier
        tmp = t.value  # Saves original value

        t.value = tmp.upper()  # Convert it to uppercase, since our internal tables uses uppercase
        id_ = tmp.lower()

        t.type = reserved_instructions.get(id_)
        if t.type is not None:
            return t

        t.type = pseudo.get(id_)
        if t.type is not None:
            return t

        t.type = regs8.get(id_)
        if t.type is not None:
            return t

        t.type = flags.get(id_)
        if t.type is not None:
            return t

        if OPTIONS.zxnext:
            t.type = zx_next_mnemonics.get(id_)
            if t.type is not None:
                return t

        t.type = regs16.get(id_, "ID")
        if t.type == "ID":
            t.value = tmp  # Restores original value

        return t

    def t_asm_PREPROCLINE(self, t):
        r'\#[ \t]*[Ll][Ii][Nn][Ee][ \t]+([0-9]+)(?:[ \t]+"((?:[^"]|"")*)")?[ \t]*\r?\n'
        import re

        match = re.match('#[ \t]*[Ll][Ii][Nn][Ee][ \t]+([0-9]+)(?:[ \t]+"((?:[^"]|"")*)")?[ \t]*\r?\n', t.value)
        global_.FILENAME = match.groups()[1] or global_.FILENAME
        self.lineno = int(match.groups()[0])

    def t_preproc_ID(self, t):
        r"[_a-zA-Z][_a-zA-Z0-9]*"  # preprocessor directives
        t.type = preprocessor.get(t.value.lower(), "ID")
        return t

    def t_COMMA(self, t):
        r","
        return t

    def t_ADDR(self, t):
        r"\$"
        return t

    def t_LB(self, t):
        r"\["
        return t

    def t_RB(self, t):
        r"\]"
        return t

    def t_LP(self, t):
        r"\("
        if t.value != "[" and OPTIONS.force_asm_brackets:
            t.type = "LPP"
        return t

    def t_RP(self, t):
        r"\)"
        if t.value != "]" and OPTIONS.force_asm_brackets:
            t.type = "RPP"
        return t

    def t_LSHIFT(self, t):
        r"<<"
        return t

    def t_RSHIFT(self, t):
        r">>"
        return t

    def t_BAND(self, t):
        r"&"
        return t

    def t_BOR(self, t):
        r"\|"
        return t

    def t_BXOR(self, t):
        r"~"
        return t

    def t_PLUS(self, t):
        r"\+"
        return t

    def t_MINUS(self, t):
        r"\-"
        return t

    def t_MUL(self, t):
        r"\*"
        return t

    def t_DIV(self, t):
        r"\/"
        return t

    def t_MOD(self, t):
        r"\%"
        return t

    def t_POW(self, t):
        r"\^"
        return t

    def t_APO(self, t):
        r"'"
        return t

    def t_CO(self, t):
        r":"
        return t

    def t_INITIAL_preproc_STRING(self, t):
        r'"(""|[^"])*"'  # a doubled quoted string
        t.value = t.value[1:-1].replace('""', '"')  # Remove quotes
        return t

    def t_INITIAL_preproc_CONTINUE(self, t):
        r"\\\r?\n"
        t.lexer.lineno += 1
        # Allows line breaking

    def t_COMMENT(self, t):
        r";.*"
        # Skip to end of line (except end of line)

    def t_INITIAL_preproc_NEWLINE(self, t):
        r"\r?\n"
        t.lexer.lineno += 1
        t.lexer.begin("INITIAL")
        return t

    def t_INITIAL_SHARP(self, t):
        r"\#"

        if self.find_column(t) == 1:
            t.lexer.begin("preproc")
        else:
            self.t_INITIAL_preproc_error(t)

    def t_INITIAL_preproc_ERROR(self, t):
        r"."
        self.t_INITIAL_preproc_error(t)

    def t_INITIAL_preproc_error(self, t):
        # error handling rule
        error(t.lexer.lineno, "illegal character '%s'" % t.value[0])

    def __init__(self):
        """Creates a new GLOBAL lexer instance"""
        self.lex = None
        self.filestack = []  # Current filename, and line number being parsed
        self.input_data = ""
        self.tokens = tokens
        self.next_token = None  # if set to something, this will be returned once

    def input(self, s: str):
        """Defines input string, removing current lexer."""
        self.input_data = s
        self.lex = lex.lex(object=self)
        self.lex.input(self.input_data)

    def token(self):
        return self.lex.token()

    def find_column(self, token):
        """Compute column:
        :param token: token instance
        """
        i = token.lexpos
        while i > 0:
            if self.input_data[i - 1] == "\n":
                break
            i -= 1

        return token.lexpos - i + 1


# --------------------- PREPROCESSOR FUNCTIONS -------------------

# Needed for states
tmp = lex.lex(object=Lexer())

if __name__ == "__main__":
    tmp.input(open(sys.argv[1]).read())
    tok = tmp.token()
    while tok:
        print(tok)
        tok = tmp.token()
