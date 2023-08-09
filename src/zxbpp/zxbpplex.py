#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Lexer for the ZXBpp (ZXBasic Preprocessor)
# ----------------------------------------------------------------------

import re
import sys
from typing import Optional

from src.api import global_
from src.ply import lex
from src.zxbpp.base_pplex import BaseLexer, ReservedDirectives
from src.zxbpp.prepro.definestable import DefinesTable

EOL = "\n"

# Names for std input/output
STDOUT = "<stdout>"
STDIN = "<stdin>"
STDERR = "<stderr>"

states = (
    ("prepro", "exclusive"),
    ("line", "exclusive"),
    ("define", "exclusive"),
    ("defargsopt", "exclusive"),
    ("defargs", "exclusive"),
    ("defexpr", "exclusive"),
    ("pragma", "exclusive"),
    ("singlecomment", "exclusive"),
    ("comment", "exclusive"),
    ("asm", "exclusive"),
    ("asmcomment", "exclusive"),
    ("if", "exclusive"),
    ("msg", "exclusive"),
)

_tokens = (
    "AND",
    "OR",
    "STRING",
    "TEXT",
    "TOKEN",
    "NEWLINE",
    "_ENDFILE_",
    "FILENAME",
    "ID",
    "INTEGER",
    "EQ",
    "PUSH",
    "POP",
    "LP",
    "LLP",
    "RRP",
    "RP",
    "COMMA",
    "CONTINUE",
    "NUMBER",
    "SEPARATOR",
    "GT",
    "GE",
    "LT",
    "LE",
    "NE",
    "PASTE",
    "STRINGIZING",
)

# List of token names.
tokens = sorted(_tokens + tuple(x.value for x in ReservedDirectives))


class Lexer(BaseLexer):
    """Own class lexer to allow multiple instances.
    This lexer is just a wrapper of the current FILESTACK[-1] lexer
    """

    def __init__(self, defines_table: Optional[DefinesTable] = None):
        """Creates a new GLOBAL lexer instance"""
        super().__init__(tokens=tokens, states=states, defines_table=defines_table)
        self.expectingDirective = False  # True if the lexer expects a preprocessor directive
        self.__COMMENT_LEVEL = 0

    # -------------- TOKEN ACTIONS --------------
    def t_INITIAL_COMMENT(self, t):
        r"(\b[Rr][Ee][Mm]\b)|'"
        t.lexer.push_state("singlecomment")

    def t_INITIAL_asmBegin(self, t):
        r"\b[aA][sS][mM]\b"
        t.type = "TOKEN"
        t.lexer.begin("asm")
        return t

    def t_asm_asmEnd(self, t):
        r"\b[Ee][Nn][Dd][ \t]+[Aa][Ss][Mm]\b"
        t.type = "TOKEN"
        t.lexer.begin("INITIAL")
        return t

    def t_asm_CONTINUE(self, t):
        r"[\\_]\r?\n"
        t.lexer.lineno += 1
        t.value = t.value[1:]
        return t

    def t_asm_COMMENT(self, t):
        r";.*"

    def t_asm_PREPROCLINE(self, t):
        r'\#[ \t]*[Ll][Ii][Nn][Ee][ \t]+([0-9]+)(?:[ \t]+"((?:[^"]|"")*)")?[ \t]*\r?\n'
        match = re.match('#[ \t]*[Ll][Ii][Nn][Ee][ \t]+([0-9]+)(?:[ \t]+"((?:[^"]|"")*)")?[ \t]*\r?\n', t.value)
        t.lexer.lineno = int(match.groups()[0])
        global_.FILENAME = match.groups()[1] or global_.FILENAME

    def t_asm_ID(self, t):
        r"[_A-Za-z][_A-Za-z0-9]*"
        return t

    def t_asm_CHAR(self, t):
        r"'[^'\n]|'''"
        t.type = "TOKEN"
        return t

    def t_asm_TOKEN(self, t):
        r"[][}{'`.:$*/+<>|&~%^-]"
        return t

    def t_INITIAL_CONTINUE(self, t):
        r"[\\_]\r?\n"
        t.lexer.lineno += 1
        return t

    def t_INITIAL_ID(self, t):
        r"[_a-zA-Z][_a-zA-Z0-9]*[$%]?"
        return t

    def t_line_singlecomment_prepro_define_defargs_defargsopt_defexpr_pragma_if_NEWLINE(self, t):
        r"\r?\n"
        t.lexer.lineno += 1
        t.lexer.pop_state()
        return t

    def t_INITIAL_asm_NEWLINE(self, t):
        r"\r?\n"
        t.lexer.lineno += 1
        return t

    def t_prepro_define_defargs_defargsopt_defexpr_pragma_COMMENT(self, t):
        r"'"
        t.lexer.begin("singlecomment")

    def t_prepro_define_pragma_defargs_defargsopt_CONTINUE(self, t):
        r"[_\\]\r?\n"
        t.lexer.lineno += 1
        return t

    def t_INITIAL_comment_beginBlock(self, t):
        r"/'"
        self.__COMMENT_LEVEL += 1
        t.lexer.begin("comment")

    def t_comment_NEWLINE(self, t):
        r"\r?\n"
        t.lexer.lineno += 1
        return t

    def t_comment_endBlock(self, t):
        r"'/"
        self.__COMMENT_LEVEL -= 1
        if not self.__COMMENT_LEVEL:
            t.lexer.begin("INITIAL")

    def t_msg_TEXT(self, t):
        r".*\n"
        t.lexer.lineno += 1
        t.lexer.begin("INITIAL")
        t.value = t.value.strip()  # remove newline and spaces
        return t

    def t_singlecomment_CONTINUE(self, t):
        r"\\\r?\n"
        t.lexer.lineno += 1
        t.value = t.value[1:]
        t.lexer.pop_state()
        return t

    # Any other character is ignored until EOL
    def t_singlecomment_comment_Skip(self, t):
        r"."

    # Allows line breaking
    def t_defexpr_CONTINUE(self, t):
        r"[\\_]\r?\n"
        t.lexer.lineno += 1
        t.value = t.value[1:]
        return t

    def t_line_prepro_pragma_defargs_define_if_skip(self, t):
        r"[ \t]+"  # ignore whitespaces and tabs

    def t_if_EQ(self, t):
        r"=="
        return t

    def t_if_NE(self, t):
        r"!=|<>"
        return t

    def t_if_GE(self, t):
        r">="
        return t

    def t_if_GT(self, t):
        r">"
        return t

    def t_if_LE(self, t):
        r"<="
        return t

    def t_if_LT(self, t):
        r"<"
        return t

    def t_if_AND(self, t):
        r"&&"
        return t

    def t_if_OR(self, t):
        r"\|\|"
        return t

    def t_prepro_ID(self, t):
        r"[._a-zA-Z][._a-zA-Z0-9]*"  # preprocessor directives
        t.type = self.reserved_directives.get(t.value.lower(), "ID")
        states_ = {"DEFINE": "define", "ERROR": "msg", "IF": "if", "LINE": "line", "PRAGMA": "pragma", "WARNING": "msg"}

        if t.type in states_:
            t.lexer.begin(states_[t.type])
        elif t.type == "ID" and self.expectingDirective:
            self.error("invalid directive #%s" % t.value)

        self.expectingDirective = False
        return t

    def t_pragma_LP(self, t):
        r"\("
        return t

    def t_pragma_RP(self, t):
        r"\)"
        return t

    def t_INITIAL_asm_defexpr_if_LLP(self, t):
        r"\("
        return t

    def t_INITIAL_asm_defexpr_if_RRP(self, t):
        r"\)"
        return t

    def t_pragma_ID(self, t):
        r"[_a-zA-Z][_a-zA-Z0-9]*"  # pragma directives
        if t.value.upper() in {"ONCE", "PUSH", "POP"}:
            t.type = t.value.upper()
        return t

    def t_defargsopt_LP(self, t):
        r"\("
        t.lexer.begin("defargs")
        return t

    # Any other char than '(' means no arglist
    def t_defargsopt_TOKEN(self, t):
        r"[ \t)@,{}:;.+*/!|&~$-]|=>|<=|<>|=|<|>"
        t.lexer.begin("defexpr")
        return t

    def t_defargsopt_STRING(self, t):
        r'"([^"\n]|"")*"'  # a doubled quoted string
        t.lexer.begin("defexpr")
        return t

    def t_defargs_LP(self, t):
        r"\("
        return t

    def t_defargs_RP(self, t):
        r"\)"
        t.lexer.begin("defexpr")
        return t

    def t_defargsopt_defexpr_ID(self, t):
        r"[_a-zA-Z][_a-zA-Z0-9]*"  # preprocessor directives
        t.lexer.begin("defexpr")
        return t

    def t_defargsopt_SEPARATOR(self, t):
        r"[ \t]+"
        t.lexer.begin("defexpr")

    def t_defargs_if_ID(self, t):
        r"[_a-zA-Z][_a-zA-Z0-9]*"  # preprocessor directives
        return t

    def t_define_ID(self, t):
        r"[_a-zA-Z][_a-zA-Z0-9]*"  # preprocessor directives
        t.lexer.begin("defargsopt")
        return t

    def t_prepro_pragma_INTEGER(self, t):
        r"[0-9]+"  # an integer number
        return t

    def t_INITIAL_pragma_prepro_defexpr_asm_if_STRING(self, t):
        r'"([^"\n]|"")*"'  # a doubled quoted string
        return t

    def t_line_INTEGER(self, t):
        r"[0-9]+"
        t.lexer.lineno = int(t.value)
        return t

    def t_line_STRING(self, t):
        r'"([^"]|"")*"'  # a doubled quoted string
        t.value = t.value[1:-1]  # Remove quotes
        self.current_file = t.value
        return t

    def t_pragma_EQ(self, t):
        r"="
        return t

    def t_INITIAL_asm_defexpr_defargs_prepro_COMMA(self, t):
        r","
        return t

    def t_INITIAL_asm_sharp(self, t):
        r"[ \t]*\#"  # Only matches if at beginning of line and "#"
        if self.find_column(t) == 1:
            t.lexer.push_state("prepro")  # Start preprocessor
            self.expectingDirective = True
        else:
            t.type = "TOKEN"
            return t

    def t_INITIAL_defexpr_TOKEN(self, t):
        r"=>|<=|>=|<>|[$!&|~@:;{}.<>^=+*/%-]"
        return t

    def t_defexpr_PASTE(self, t):
        r"[ \t]*\#\#[ \t]*"
        return t

    def t_defexpr_STRINGIZING(self, t):
        r"\#[ \t]*"
        return t

    def t_INITIAL_defexpr_asm_SEPARATOR(self, t):
        r"[ \t]+"
        return t

    def t_INITIAL_defexpr_asm_HEXA(self, t):
        r"([0-9][0-9a-fA-F]*[hH])|(\$[0-9a-fA-F]+)"
        # Hexadecimal numbers
        t.type = "NUMBER"
        return t

    def t_INITIAL_defexpr_asm_BIN(self, t):
        r"(%[01]+)|([01]+[bB])"  # A Binary integer
        # Note 00B is a 0 binary, but
        # 00Bh is a 12 in hex. So this pattern must come
        # after HEXA
        t.type = "NUMBER"
        return t

    def t_INITIAL_defexpr_asm_if_NUMBER(self, t):
        # This pattern must come AFTER t_HEXA and t_BIN
        r"(([0-9]+(\.[0-9]+)?)|(\.[0-9]+))([eE][-+]?[0-9]+)?"
        return t

    def t_prepro_FILENAME(self, t):
        r"<[^>]*>"
        t.value = t.value[1:-1]  # Remove quotes
        return t

    def t_INITIAL_line_defargs_defargsopt_prepro_define_defexpr_pragma_comment_singlecomment_ANY(self, t):
        r"."
        self.error("illegal preprocessor character '%s'" % t.value[0])

    def t_INITIAL_if_line_defargs_defargsopt_prepro_define_defexpr_pragma_comment_singlecomment_error(self, t):
        """error handling rule. Should never happen!"""
        pass  # The lexer will raise an exception here. This is intended

    def t_asm_asmcomment_if_ANY(self, t):
        r"."
        self.error("illegal preprocessor character '%s'" % t.value[0])

    def t_asm_asmcomment_if_msg_error(self, t):
        """error handling rule. Should never happen!"""
        pass


# --------------------- PREPROCESSOR FUNCTIONS -------------------


# Needed for states
lex.lex(object=Lexer())

# ------------------ Test if called from cmd line ---------------
if __name__ == "__main__":  # For testing purposes
    lexer = Lexer()
    lexer.include(sys.argv[1])

    while 1:
        tok = lexer.token()
        if not tok:
            break
        print(tok)
