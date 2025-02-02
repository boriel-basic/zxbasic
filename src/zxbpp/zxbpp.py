#!/usr/bin/env python3
# vim: ts=4:sw=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Parser for the ZXBpp (ZXBasic Preprocessor)
# ----------------------------------------------------------------------

import argparse
import os
import re
import sys
from dataclasses import dataclass
from enum import Enum, unique
from typing import Any, NamedTuple

from src import arch
from src.api import config, global_, utils
from src.ply import yacc
from src.zxbpp import zxbasmpplex, zxbpplex
from src.zxbpp.base_pplex import STDIN
from src.zxbpp.prepro import ID, Arg, ArgList, DefinesTable, MacroCall, output
from src.zxbpp.prepro.builtinmacro import BuiltinMacro
from src.zxbpp.prepro.exceptions import PreprocError
from src.zxbpp.prepro.operators import Concatenation, Stringizing
from src.zxbpp.prepro.output import error, warning
from src.zxbpp.zxbpplex import tokens  # noqa


@unique
class PreprocMode(str, Enum):
    BASIC = "BASIC"
    ASM = "ASM"


# Generated output
OUTPUT = ""

# Global macro (#defines) table
ID_TABLE = DefinesTable()

# Set to BASIC or ASM depending on the Lexer context
# e.g. for .ASM files should be set to zxbasmpplex.Lexer()
# Use setMode('ASM' or 'BASIC') to change this FLAG
LEXER: zxbasmpplex.Lexer | zxbpplex.Lexer = zxbpplex.Lexer(defines_table=ID_TABLE)

# CURRENT working directory for this cpp
CURRENT_DIR = None

# Default include path
INCLUDEPATH: list[str] = ["stdlib", "runtime"]

# Enabled to FALSE if IFDEF failed
ENABLED: bool = True

# Defines Regexp to match filenames
RE_LOCAL_FIRST_FILENAME = re.compile('^"([^"]|"")*"$')
RE_GLOBAL_FIRST_FILENAME = re.compile("^<[^>]+>$")


class IfDef(NamedTuple):
    enabled: bool
    line: int


class ParentIncludingFile(NamedTuple):
    file_name: str
    lineno: int


@dataclass
class IncludedFileInfo:
    once: bool  # whether this file is
    parents: list[ParentIncludingFile]


# Files already includes, with a list of file, line where they were
# included sinc a file can be included more than once.
INCLUDED: dict[str, IncludedFileInfo] = {}

# IFDEFS array
IFDEFS: list[IfDef] = []  # Push (Line, state here)

precedence = (
    ("nonassoc", "DUMMY"),
    ("left", "OR"),
    ("left", "AND"),
    ("left", "EQ", "NE", "LT", "LE", "GT", "GE"),
    ("right", "LLP"),
    ("left", "PASTE", "STRINGIZING"),
)


def remove_spaces(x: str) -> str:
    if not x:
        return x

    return x.strip(" \t") or " "


def reset_id_table():
    """Initializes ID_TABLE with default DEFINES
    (i.e. those that derives from OPTIONS)
    """
    ID_TABLE.clear()

    for name, val in config.OPTIONS.__DEFINES.items():
        ID_TABLE.define(name, value=val, lineno=0)

    for macro_name, macro_func in LEXER.builtin_macros.items():
        LEXER.set_macro(macro_name, BuiltinMacro(macro_name=macro_name, func=macro_func))


def init():
    """Initializes the preprocessor"""
    global OUTPUT
    global INCLUDED
    global CURRENT_DIR
    global ENABLED
    global IFDEFS

    config.OPTIONS(config.Action.ADD_IF_NOT_DEFINED, name="debug_zxbpp", type=bool, default=False)
    global_.FILENAME = STDIN
    OUTPUT = ""
    INCLUDED = {}
    CURRENT_DIR = ""
    ENABLED = True
    IFDEFS = []
    global_.has_errors = 0
    global_.error_msg_cache.clear()
    parser.defaulted_states = {}
    del output.CURRENT_FILE[:]

    reset_id_table()


def get_include_path() -> str:
    """Default include path using a tricky sys calls."""
    return os.path.realpath(
        os.path.join(os.path.dirname(__file__), os.path.pardir, "lib", "arch", config.OPTIONS.architecture or "")
    )


def set_include_path():
    global INCLUDEPATH
    pwd = get_include_path()
    INCLUDEPATH = [os.path.join(pwd, "stdlib"), os.path.join(pwd, "runtime")]


def setMode(mode: PreprocMode) -> None:
    global LEXER

    mode = mode.upper()
    if mode not in list(PreprocMode):
        raise PreprocError('Invalid mode "%s"' % mode, lineno=LEXER.lineno)

    lexers = {
        PreprocMode.ASM: zxbasmpplex.Lexer(defines_table=ID_TABLE),
        PreprocMode.BASIC: zxbpplex.Lexer(defines_table=ID_TABLE),
    }

    LEXER = lexers[PreprocMode(mode)]


def search_filename(fname: str, lineno: int, local_first: bool) -> str:
    """Search a filename into the list of the include path.
    If local_first is true, it will try first in the current directory of
    the file being analyzed.
    """
    fname = utils.sanitize_filename(fname)

    assert CURRENT_DIR is not None
    i_path: list[str] = [CURRENT_DIR] + INCLUDEPATH if local_first else list(INCLUDEPATH)
    i_path.extend(config.OPTIONS.include_path.split(":") if config.OPTIONS.include_path else [])

    if os.path.isabs(fname):
        if os.path.isfile(fname):
            return fname
    else:
        for dir_ in i_path:
            path = utils.sanitize_filename(os.path.join(dir_, fname))
            if os.path.exists(path):
                return path

    error(lineno, "file '%s' not found" % fname)
    return ""


def include_file(filename: str, lineno: int, local_first: bool) -> str:
    """Performs a file inclusion (#include) in the preprocessor.
    Writes down that "filename" was included at the current file,
    at line <lineno>.

    If local_first is True, then it will first search the file in the
    local path before looking for it in the include path chain.
    This is used when doing a #include "filename".
    """
    global CURRENT_DIR

    filename = search_filename(filename, lineno, local_first)
    abs_filename = utils.get_absolute_filename_path(filename)
    if abs_filename not in INCLUDED:
        INCLUDED[abs_filename] = IncludedFileInfo(once=False, parents=[])
    elif INCLUDED[abs_filename].once:
        # Empty file (already included)
        LEXER.next_token = "_ENDFILE_"
        return ""

    if output.CURRENT_FILE:  # Added from which file, line
        INCLUDED[abs_filename].parents.append(ParentIncludingFile(output.CURRENT_FILE[-1], lineno))

    output.CURRENT_FILE.append(filename)
    CURRENT_DIR = os.path.dirname(filename)
    return LEXER.include(filename)


def include_once(filename: str, lineno: int, local_first: bool) -> str:
    """Performs a file inclusion (#include) in the preprocessor.
    Writes down that "filename" was included at the current file,
    at line <lineno>.

    The file is ignored if it was previously included (a warning will
    be emitted though).

    If local_first is True, then it will first search the file in the
    local path before looking for it in the include path chain.
    This is used when doing a #include "filename".
    """
    filename = search_filename(filename, lineno, local_first)
    abs_filename = utils.get_absolute_filename_path(filename)
    if abs_filename not in INCLUDED:  # If not already included
        return include_file(filename, lineno, local_first)  # include it and return

    # Now checks if the file has been included more than once
    if len(INCLUDED[abs_filename].parents) > 1:
        parent_file, lineno = INCLUDED[abs_filename].parents[0]
        warning(
            lineno,
            "file '%s' already included more than once, in file '%s' at line %i" % (filename, parent_file, lineno),
        )

    # Empty file (already included)
    LEXER.next_token = "_ENDFILE_"
    return ""


def expand_macros(macros: list[Any], lineno: int) -> str | None:
    try:
        tmp = "".join(remove_spaces(str(x())) if isinstance(x, MacroCall) else x for x in macros)
    except PreprocError as v:
        error(v.lineno, v.message)
        return None

    if "\n" in tmp:
        tmp += f"\n#line {lineno + 1}"
    tmp += "\n"

    return tmp


def to_bool(expr: str | bool | int) -> int:
    if isinstance(expr, str) and expr.isdigit():
        expr = int(expr)

    return int(bool(expr))


def to_int(expr: str | int) -> int:
    if isinstance(expr, str) and expr.isdigit():
        expr = int(expr)
    else:
        expr = 0

    return expr


# -------- GRAMMAR RULES for the preprocessor ---------
def p_start(p):
    """start : program"""
    global OUTPUT

    OUTPUT += "".join(p[1])


def p_program(p):
    """program : include_file
    | line
    | init
    | undef
    | ifdef
    | require
    | pragma
    | errormsg
    | warningmsg
    """
    p[0] = p[1]


def p_program_tokenstring(p):
    """program : defs NEWLINE"""
    tmp = expand_macros(p[1], p.lineno(2))
    if tmp is None:
        p[0] = []
        return

    p[0] = [tmp]


def p_program_tokenstring_2(p):
    """program : define NEWLINE"""
    p[0] = p[1] + [p[2]]


def p_program_char(p):
    """program : program include_file
    | program line
    | program init
    | program undef
    | program ifdef
    | program require
    | program pragma
    | program errormsg
    | program warningmsg
    """
    p[0] = p[1] + p[2]


def p_program_newline(p):
    """program : program defs NEWLINE"""
    tmp = expand_macros(p[2], p.lineno(3))
    if tmp is None:
        p[0] = []
        return

    p[0] = p[1]
    p[0].append(tmp)


def p_program_newline_2(p):
    """program : program define NEWLINE"""
    p[0] = p[1] + [f'#line {p.lineno(3) + 1} "{output.CURRENT_FILE[-1]}"\n']


def p_token(p):
    """token : STRING
    | TOKEN
    | CONTINUE
    | SEPARATOR
    | NUMBER
    """
    p[0] = p[1]


def p_include_file(p):
    """include_file : include NEWLINE program _ENDFILE_"""
    global CURRENT_DIR
    p[0] = [p[1] + p[2]] + p[3] + [p[4]]
    output.CURRENT_FILE.pop()  # Remove top of the stack
    CURRENT_DIR = os.path.dirname(output.CURRENT_FILE[-1])


def p_include_file_empty(p):
    """include_file : include NEWLINE _ENDFILE_"""  # This happens when an IFDEF is FALSE
    p[0] = [p[2]]


def p_include_once_empty(p):
    """include_file : include_once NEWLINE _ENDFILE_"""
    p[0] = [p[2]]  # Include once already included. Nothing done.


def p_include_once_ok(p):
    """include_file : include_once NEWLINE program _ENDFILE_"""
    global CURRENT_DIR
    p[0] = [p[1] + p[2]] + p[3] + [p[4]]
    output.CURRENT_FILE.pop()  # Remove top of the stack
    CURRENT_DIR = os.path.dirname(output.CURRENT_FILE[-1])


def p_include_fname(p):
    """include : INCLUDE FILENAME"""
    if ENABLED:
        p[0] = include_file(p[2], p.lineno(2), local_first=False)
    else:
        p[0] = []
        p.lexer.next_token = "_ENDFILE_"


def p_include_macro(p):
    """include : INCLUDE expr"""
    global_fist = RE_GLOBAL_FIRST_FILENAME.match(p[2])
    local_first = RE_LOCAL_FIRST_FILENAME.match(p[2])
    if global_fist is None and local_first is None:
        error(p.lineno(1), f"invalid filename {p[2]}")
        p[0] = []
        return

    if ENABLED:
        p[0] = include_file(p[2][1:-1], p.lineno(2), local_first=local_first is not None)
    else:
        p[0] = []
        p.lexer.next_token = "_ENDFILE_"


def p_include_once(p):
    """include_once : INCLUDE ONCE STRING"""
    if ENABLED:
        p[0] = include_once(p[3][1:-1], p.lineno(3), local_first=True)
    else:
        p[0] = []

    if not p[0]:
        p.lexer.next_token = "_ENDFILE_"


def p_include_once_fname(p):
    """include_once : INCLUDE ONCE FILENAME"""
    p[0] = []

    if ENABLED:
        p[0] = include_once(p[3], p.lineno(3), local_first=False)
    else:
        p[0] = []

    if not p[0]:
        p.lexer.next_token = "_ENDFILE_"


def p_line(p):
    """line : LINE INTEGER NEWLINE"""
    if ENABLED:
        p[0] = ["#%s %s%s" % (p[1], p[2], p[3])]
    else:
        p[0] = []


def p_line_file(p):
    """line : LINE INTEGER STRING NEWLINE"""
    if ENABLED:
        p[0] = ['#%s %s "%s"%s' % (p[1], p[2], p[3], p[4])]
    else:
        p[0] = []


def p_require_file(p):
    """require : REQUIRE STRING NEWLINE"""
    p[0] = ["#%s %s\n" % (p[1], utils.sanitize_filename(p[2]))]


def p_init(p):
    """init : INIT ID NEWLINE"""
    p[0] = ['#%s "%s"\n' % (p[1], p[2])]


def p_init_str(p):
    """init : INIT STRING NEWLINE"""
    p[0] = ["#%s %s\n" % (p[1], p[2])]


def p_undef(p):
    """undef : UNDEF ID"""
    if ENABLED:
        ID_TABLE.undef(p[2])

    p[0] = []


def p_errormsg(p):
    """errormsg : ERROR TEXT"""
    if ENABLED:
        error(p.lineno(1), p[2])
    p[0] = []


def p_warningmsg(p):
    """warningmsg : WARNING TEXT"""
    if ENABLED:
        warning(p.lineno(1), p[2])
    p[0] = []


def p_define(p):
    """define : DEFINE ID params defs"""
    id_ = p[2]
    params = p[3]
    defs = p[4]

    if ENABLED:
        if defs:
            if isinstance(defs[0], str) and defs[0] in " \t":  # remove leading whitespaces
                defs[0] = defs[0].lstrip(" \t")
            else:
                output.warning_missing_whitespace_after_macro(p.lineno(1), p.lexer.current_file)

        ID_TABLE.define(
            id_,
            args=params,
            value=defs,
            lineno=p.lineno(2),
            fname=output.CURRENT_FILE[-1],
        )
    p[0] = []


def p_define_params_epsilon(p):
    """params :"""
    p[0] = None


def p_define_params_empty(p):
    """params : LP RP"""
    # Defines the 'epsilon' parameter
    p[0] = [ID("", value="", args=None, lineno=p.lineno(1), fname=output.CURRENT_FILE[-1])]


def p_define_params_paramlist(p):
    """params : LP paramlist RP"""
    for i in p[2]:
        if not isinstance(i, ID):
            error(p.lineno(3), '"%s" might not appear in a macro parameter list' % str(i))
            p[0] = None
            return

    names = [x.name for x in p[2]]
    for i in range(len(names)):
        if names[i] in names[i + 1 :]:
            error(p.lineno(3), 'Duplicated name parameter "%s"' % (names[i]))
            p[0] = None
            return

    p[0] = p[2]


def p_paramlist_single(p):
    """paramlist : ID"""
    p[0] = [ID(p[1], value="", args=None, lineno=p.lineno(1), fname=output.CURRENT_FILE[-1])]


def p_paramlist_paramlist(p):
    """paramlist : paramlist COMMA ID"""
    p[0] = p[1] + [ID(p[3], value="", args=None, lineno=p.lineno(1), fname=output.CURRENT_FILE[-1])]


def p_pragma_id(p):
    """pragma : PRAGMA ID"""
    p[0] = ["#%s %s" % (p[1], p[2])]


def p_pragma_id_expr(p):
    """pragma : PRAGMA ID EQ ID
    | PRAGMA ID EQ INTEGER
    """
    p[0] = ["#%s %s %s %s" % (p[1], p[2], p[3], p[4])]


def p_pragma_id_string(p):
    """pragma : PRAGMA ID EQ STRING"""
    p[0] = ["#%s %s %s %s" % (p[1], p[2], p[3], p[4][1:-1])]


def p_pragma_push(p):
    """pragma : PRAGMA PUSH LP ID RP
    | PRAGMA POP LP ID RP
    """
    p[0] = ["#%s %s%s%s%s" % (p[1], p[2], p[3], p[4], p[5])]


def p_pragma_once(p):
    """pragma : PRAGMA ONCE"""
    abs_filename = utils.get_absolute_filename_path(output.CURRENT_FILE[-1])
    if abs_filename not in INCLUDED:
        INCLUDED[abs_filename] = IncludedFileInfo(once=False, parents=[])

    INCLUDED[abs_filename].once = True
    p[0] = []


def p_ifdef(p):
    """ifdef : if_header NEWLINE program ENDIF"""
    global ENABLED

    if ENABLED:
        p[0] = [p[2]] + p[3]
    else:
        p[0] = []

    p[0] += ['#line %i "%s"' % (p.lineno(4) + 1, output.CURRENT_FILE[-1])]
    ENABLED = IFDEFS.pop().enabled


def p_ifdef_else(p):
    """ifdef : ifdefelsea ifdefelseb ENDIF"""
    global ENABLED

    ENABLED = IFDEFS.pop().enabled
    if ENABLED:
        p[0] = p[1] + p[2]
    else:
        p[0] = []

    p[0] += ['#line %i "%s"' % (p.lineno(3) + 1, output.CURRENT_FILE[-1])]


def p_ifdef_else_a(p):
    """ifdefelsea : if_header NEWLINE program"""
    global ENABLED

    p[0] = []
    if IFDEFS[-1].enabled:
        if p[1]:
            p[0] = [p[2]] + p[3]
        ENABLED = not p[1]


def p_ifdef_else_b(p):
    """ifdefelseb : ELSE NEWLINE program"""
    global ENABLED

    if ENABLED:
        p[0] = ['#line %i "%s"%s' % (p.lineno(1) + 1, output.CURRENT_FILE[-1], p[2])]
        p[0] += p[3]
    else:
        p[0] = []


def p_if_header(p):
    """if_header : IFDEF ID"""
    global ENABLED

    IFDEFS.append(IfDef(ENABLED, p.lineno(2)))
    if ENABLED:
        ENABLED = ID_TABLE.defined(p[2])

    p[0] = ENABLED


def p_ifn_header(p):
    """if_header : IFNDEF ID"""
    global ENABLED

    IFDEFS.append(IfDef(ENABLED, p.lineno(2)))
    if ENABLED:
        ENABLED = not ID_TABLE.defined(p[2])

    p[0] = ENABLED


def p_if_expr_header(p):
    """if_header : IF expr"""
    global ENABLED

    IFDEFS.append(IfDef(ENABLED, p.lineno(2)))
    if ENABLED:
        ENABLED = bool(int(p[2])) if p[2].isdigit() else ID_TABLE.defined(p[2])

    p[0] = ENABLED


def p_expr(p):
    """expr : macrocall"""
    p[0] = str(p[1]()).strip()


def p_expr_val(p):
    """expr : NUMBER"""
    p[0] = p[1]


def p_expr_str(p):
    """expr : STRING"""
    p[0] = p[1]


def p_exprand(p):
    """expr : expr AND expr"""
    p[0] = "1" if to_bool(p[1]) and to_bool(p[3]) else "0"


def p_expror(p):
    """expr : expr OR expr"""
    p[0] = "1" if to_bool(p[1]) or to_bool(p[3]) else "0"


def p_exprne(p):
    """expr : expr NE expr"""
    p[0] = "1" if p[1] != p[3] else "0"


def p_expreq(p):
    """expr : expr EQ expr"""
    p[0] = "1" if p[1] == p[3] else "0"


def p_exprlt(p):
    """expr : expr LT expr"""
    p[0] = "1" if to_int(p[1]) < to_int(p[3]) else "0"


def p_exprle(p):
    """expr : expr LE expr"""
    p[0] = "1" if to_int(p[1]) <= to_int(p[3]) else "0"


def p_exprgt(p):
    """expr : expr GT expr"""
    p[0] = "1" if to_int(p[1]) > to_int(p[3]) else "0"


def p_exprge(p):
    """expr : expr GE expr"""
    p[0] = "1" if to_int(p[1]) >= to_int(p[3]) else "0"


def p_expr_par(p):
    """expr : LLP expr RRP"""
    p[0] = p[2]


def p_defs_list_eps(p):
    """defs :"""
    p[0] = []


def p_defs_list(p):
    """defs : defs def"""
    p[0] = p[1]
    p[0].append(p[2])


def p_def(p):
    """def : token
    | COMMA
    | RRP
    | LLP
    """
    p[0] = p[1]


def p_def_macrocall(p):
    """def : macrocall %prec DUMMY"""
    p[0] = p[1]


def p_macrocall(p):
    """macrocall : ID"""
    p[0] = MacroCall(p.lexer.current_file, p.lineno(1), ID_TABLE, p[1], None)


def p_macrocall_args(p):
    """macrocall : macrocall args"""
    p[0] = MacroCall(p.lexer.current_file, p[2].end_lineno, ID_TABLE, p[1], p[2])


def p_macrocall_paste(p):
    """macrocall : macrocall PASTE macrocall"""
    p[0] = Concatenation(p.lexer.current_file, p[1].lineno, ID_TABLE, p[1], p[3])


def p_macrocall_stringizing(p):
    """macrocall : STRINGIZING macrocall"""
    p[0] = Stringizing(p.lexer.current_file, p[2].lineno, ID_TABLE, p[2])


def p_args(p):
    """args : LLP arglist RRP"""
    p[0] = p[2]
    p[0].start_lineno = p.slice[1].lineno
    p[0].end_lineno = p.slice[3].lineno


def p_arglist(p):
    """arglist : arglist COMMA arg"""
    p[1].addNewArg(p[3])
    p[0] = p[1]


def p_arglist_arg(p):
    """arglist : arg"""
    p[0] = ArgList(ID_TABLE)
    p[0].addNewArg(p[1])


def p_arg_eps(p):
    """arg :"""
    p[0] = Arg()


def p_arg_argstring(p):
    """arg : argstring"""
    p[0] = p[1]


def p_argstring(p):
    """argstring : token
    | macrocall %prec DUMMY
    """
    p[0] = Arg(p[1])


def p_argstring_argslist(p):
    """argstring : LLP arglist RRP"""
    p[0] = Arg(p[2])


def p_argstring_token(p):
    """argstring : argstring token
    | argstring macrocall %prec DUMMY
    """
    p[0] = p[1]
    p[0].addToken(p[2])


def p_argstring_argstring(p):
    """argstring : argstring LLP arglist RRP"""
    p[0] = p[1]
    p[0].addToken(p[3])


# --- YYERROR


def p_error(p):
    if p is not None:
        if p.type == "NEWLINE":
            error(
                p.lineno,
                "Syntax error. Unexpected end of line",
                output.CURRENT_FILE[-1],
            )
        elif p.type == "_ENDFILE_":
            error(
                p.lineno,
                "Syntax error. Unexpected end of file",
                output.CURRENT_FILE[-1],
            )
        else:
            value = p.value
            value = "".join(["|%s|" % hex(ord(x)) if x < " " else x for x in value])
            error(
                p.lineno,
                "Syntax error. Unexpected token '%s' [%s]" % (value, p.type),
                output.CURRENT_FILE[-1],
            )
    else:
        config.OPTIONS.stderr.write("General syntax error at preprocessor (unexpected End of File?)")
    global_.has_errors += 1


def filter_(input_, filename="<internal>", state="INITIAL"):
    """Filter the input string thought the preprocessor.
    result is appended to OUTPUT global str
    """
    global CURRENT_DIR

    prev_dir = CURRENT_DIR
    output.CURRENT_FILE.append(filename)
    CURRENT_DIR = os.path.dirname(output.CURRENT_FILE[-1])
    LEXER.input(input_, filename)
    LEXER.lex.begin(state)
    parser.parse(lexer=LEXER, debug=config.OPTIONS.debug_zxbpp)
    output.CURRENT_FILE.pop()
    CURRENT_DIR = prev_dir


def main(argv):
    global OUTPUT, ID_TABLE, ENABLED, CURRENT_DIR

    ENABLED = True
    OUTPUT = ""
    set_include_path()

    if argv:
        output.CURRENT_FILE.append(argv[0])
    else:
        output.CURRENT_FILE.append(global_.FILENAME)
    CURRENT_DIR = os.path.dirname(output.CURRENT_FILE[-1])

    if config.OPTIONS.sinclair:
        included_file = search_filename("sinclair.bas", 0, local_first=False)
        if not included_file:
            return None

        OUTPUT += include_once(included_file, 0, local_first=False)
        if OUTPUT and OUTPUT[-1] != "\n":
            OUTPUT += "\n"

        parser.parse(lexer=LEXER, debug=config.OPTIONS.debug_zxbpp)
        output.CURRENT_FILE.pop()
        CURRENT_DIR = os.path.dirname(output.CURRENT_FILE[-1])

    prev_file = global_.FILENAME
    global_.FILENAME = output.CURRENT_FILE[-1]
    OUTPUT += LEXER.include(output.CURRENT_FILE[-1])
    if OUTPUT and OUTPUT[-1] != "\n":
        OUTPUT += "\n"

    parser.parse(lexer=LEXER, debug=config.OPTIONS.debug_zxbpp)
    output.CURRENT_FILE.pop()
    global_.FILENAME = prev_file
    return global_.has_errors


parser = utils.get_or_create("zxbpp", lambda: yacc.yacc(debug=True))
parser.defaulted_states = {}


# ------- ERROR And Warning messages ----------------


def entry_point(args=None):
    if args is None:
        args = sys.argv[1:]

    config.init()
    init()
    setMode(PreprocMode.BASIC)

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        dest="output_file",
        default=None,
        help="Sets output file. Default is to output to console (STDOUT)",
    )
    parser.add_argument(
        "-d",
        "--debug",
        dest="debug",
        default=config.OPTIONS.debug_level,
        action="count",
        help="Enable verbosity/debugging output. Additional -d increases verbosity/debug level",
    )
    parser.add_argument(
        "-e",
        "--errmsg",
        type=str,
        dest="stderr",
        default=None,
        help="Error messages file. Standard error console by default (STDERR)",
    )
    parser.add_argument(
        "input_file",
        type=str,
        default=None,
        nargs="?",
        help="File to parse. If not specified, console input will be used (STDIN)",
    )
    parser.add_argument(
        "--arch",
        type=str,
        default=arch.AVAILABLE_ARCHITECTURES[0],
        help=f"Target architecture (defaults is'{arch.AVAILABLE_ARCHITECTURES[0]}'). "
        f"Available architectures: {','.join(arch.AVAILABLE_ARCHITECTURES)}",
    )
    parser.add_argument(
        "--expect-warnings",
        default=config.OPTIONS.expected_warnings,
        type=int,
        help="Expects N warnings: first N warnings will be silenced",
    )

    options = parser.parse_args(args=args)
    config.OPTIONS.debug_level = options.debug
    config.OPTIONS.debug_zxbpp = config.OPTIONS.debug_level > 0
    config.OPTIONS.expected_warnings = options.expect_warnings

    if options.arch not in arch.AVAILABLE_ARCHITECTURES:
        parser.error(f"Invalid architecture '{options.arch}'")  # Exits with error

    config.OPTIONS.architecture = options.arch

    if options.stderr:
        config.OPTIONS.stderr_filename = options.stderr
        config.OPTIONS.stderr = utils.open_file(config.OPTIONS.stderr_filename, "wt", "utf-8")

    if options.input_file:
        _, ext = os.path.splitext(options.input_file)
        if ext.lower() == "asm":
            setMode(PreprocMode.ASM)

    result = main([options.input_file] if options.input_file else [])
    if not global_.has_errors:  # ok?
        if options.output_file:
            with utils.open_file(options.output_file, "wt", "utf-8") as output_file:
                output_file.write(OUTPUT)
        else:
            config.OPTIONS.stdout.write(OUTPUT)

    return result


if __name__ == "__main__":
    sys.exit(entry_point())
