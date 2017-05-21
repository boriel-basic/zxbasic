#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim:ts=4:et:sw=4

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
# ----------------------------------------------------------------------

from ply import lex
from keywords import KEYWORDS as reserved


def syntax_error(*args):
    """ Dummy function that will be called for invalid tokens.
    Should be overwritten.
    """
    pass


ASM = ''  # Set to asm block when commenting
ASMLINENO = 0  # Line of ASM INLINE beginning
LABELS_ALLOWED = True  # Whether numbers and IDs at beginning of line are taken as LABELS
IN_STATE = False  # True if inside a state like "ASM"
__STRING = ''  # STRING Content
__COMMENT_LEVEL = 0  # Nested comments level

states = (('string', 'exclusive'),
          ('asm', 'exclusive'),
          ('preproc', 'exclusive'),
          ('comment', 'exclusive'),
          ('bin', 'exclusive')
          )

# List of token names.
_tokens = (
    'NUMBER', 'PLUS', 'MINUS', 'MUL', 'DIV', 'POW',
    'LP', 'RP', 'LT', 'LBRACE', 'RBRACE',
    'EQ', 'GT', 'LE', 'GE', 'NE', 'ID',
    'NEWLINE', 'CO', 'SC', 'COMMA', 'STRC',
    'RIGHTARROW', 'ADDRESSOF', 'LABEL')

preprocessor = {
    'line': '_LINE',
    'init': '_INIT',
    'require': '_REQUIRE',
    'pragma': '_PRAGMA',
    'push': '_PUSH',
    'pop': '_POP',
}

macros = (
    '__LINE__', '__FILE__',
)

tokens = sorted(_tokens + tuple(set(reserved.values())) + tuple(preprocessor.values()) + macros)


def t_INITIAL_bin_comment_beginBlockComment(t):
    r"/'"
    global __COMMENT_LEVEL

    __COMMENT_LEVEL += 1
    t.lexer.push_state('comment')


def t_comment_endBlockComment(t):
    r"'/"
    global __COMMENT_LEVEL

    __COMMENT_LEVEL -= 1
    # if not __COMMENT_LEVEL:
    #    t.lexer.begin('INITIAL')
    t.lexer.pop_state()


def t_comment_NEWLINE(t):
    r'\r?\n'
    t.lexer.lineno += 1


def t_comment_charComment(t):
    r"."
    pass


def t_PLUS(t):
    r'\+'

    return t


def t_MINUS(t):
    r'-'

    return t


def t_MUL(t):
    r'\*'

    return t


def t_DIV(t):
    r'/'

    return t


def t_LP(t):
    r'\('

    return t


def t_RP(t):
    r'\)'

    return t


def t_CO(t):
    r':'

    return t


def t_SC(t):
    r';'

    return t


def t_COMMA(t):
    r','

    return t


def t_GE(t):
    r'>='

    return t


def t_LE(t):
    r'<='

    return t


def t_NE(t):
    r'<>'

    return t


def t_RIGHTARROW(t):
    r'=>'

    return t


def t_EQ(t):
    r'='

    return t


def t_SHL(t):
    r'<<'

    return t


def t_LT(t):
    r'<'

    return t


def t_SHR(t):
    r'>>'

    return t


def t_GT(t):
    r'>'

    return t


def t_POW(t):
    r'\^'

    return t


def t_BXOR(t):
    r'~'

    return t


def t_BAND(t):
    r'&'

    return t


def t_BOR(t):
    r'\|'

    return t


def t_BNOT(t):
    r'!'

    return t


def t_INITIAL_SHARP(t):
    r'\#'

    if find_column(t) == 1:
        t.lexer.begin('preproc')
    else:
        t_INITIAL_bin_string_asm_preproc_comment_error(t)


def t_LBRACE(t):
    r'\{'

    return t


def t_RBRACE(t):
    r'\}'

    return t


def t_MACROS(t):
    r'__[a-zA-Z]+__'

    if t.value in macros:
        t.type = t.value
        return t

    syntax_error(t.lexer.lineno, "unknown macro '%s'" % t.value)
    sys.exit(1)


def t_ADDRESSOF(t):
    r'@'

    return t


def t_str(t):
    r'"'

    t.lexer.begin('string')


def t_string_COPYRIGHT(t):
    r'\\\*'
    global __STRING

    __STRING += chr(127)


def t_string_NGRAPH(t):
    r"\\[ '.:][ '.:]"
    global __STRING

    P = {' ': 0, "'": 2, '.': 8, ':': 10}
    N = {' ': 0, "'": 1, '.': 4, ':': 5}

    __STRING += chr(128 + P[t.value[1]] + N[t.value[2]])


def t_string_UDG(t):
    r"\\[A-Ua-u]"
    global __STRING

    __STRING += chr(79 + ord(t.value[1].upper()))


def t_string_CODE(t):
    r'\\\#[0-9][0-9][0-9]'

    global __STRING
    # an ASCII code

    __STRING += chr(int(t.value[2:]))


def t_string_PAPERCODE(t):
    r"\\{p[0-9]}"
    # Paper code

    global __STRING
    __STRING += chr(17) + chr(int(t.value[3]))


def t_string_INKCODE(t):
    r"\\{i[0-9]}"
    # Ink code

    global __STRING
    __STRING += chr(16) + chr(int(t.value[3]))


def t_string_FLASH(t):
    r"\\{f[01]}"
    # flash code

    global __STRING
    __STRING += chr(18) + chr({'0': 0, '1': 1}[t.value[3]])


def t_string_BRIGHT(t):
    r"\\{b[01]}"
    # bright code

    global __STRING
    __STRING += chr(19) + chr({'0': 0, '1': 1}[t.value[3]])


def t_string_INVERSE(t):
    r"\\{v[in01]}"
    # Inverse code

    global __STRING
    __STRING += chr(20) + chr({'n': 0, 'i': 1, '0': 0, '1': 1}[t.value[3]])


def t_string_ITALIC(t):
    r"\\{I[01]}"
    # Italic Code

    global __STRING
    __STRING += chr(15) + chr({'0': 0, '1': 1}[t.value[3]])


def t_string_BOLD(t):
    r"\\{B[01]}"
    # Italic Code

    global __STRING
    __STRING += chr(14) + chr({'0': 0, '1': 1}[t.value[3]])


def t_string_DQUOTE(t):
    r'""'
    global __STRING

    __STRING += '"'


def t_string_STRC(t):
    r'"'

    global __STRING
    t.lexer.begin('INITIAL')
    t.value = __STRING
    __STRING = ''

    return t


def t_string_CHAR(t):
    r'[^"]'

    global __STRING
    __STRING += t.value


def t_asm(t):
    r'\b[aA][sS][mM]\b'

    global ASM, ASMLINENO, IN_STATE
    t.lexer.begin('asm')

    ASM = ''
    ASMLINENO = t.lexer.lineno
    IN_STATE = True


def t_asm_ASM(t):
    r'\b[eE][nN][dD][ \t]+[aA][sS][mM]\b'

    global IN_STATE

    t.lexer.begin('INITIAL')
    t.value = ASM
    t.lineno = ASMLINENO - 1
    IN_STATE = False

    return t


def t_asm_STRING(t):
    r'"[^"]*"'
    global ASM

    ASM += t.value


def t_asm_comment(t):
    r';.*'


def t_asm_next(t):
    r'.'
    global ASM

    ASM += t.value


def t_asm_NEWLINE(t):
    r'\r?\n'
    global ASM

    ASM += t.value
    t.lexer.lineno += 1


# rem lines
def t_rem(t):
    r"([']|[Rr][Ee][Mm][ \t]).*"
    pass


def t_EmptyRem(t):
    r"([']|[Rr][Ee][Mm])\r?\n"
    t.lexer.begin('INITIAL')
    t.lexer.lineno += 1

    t.value = '\n'
    t.type = 'NEWLINE'

    return t


def t_preproc_ID(t):
    r'[_A-Za-z]+'
    t.value = t.value.strip()
    t.type = preprocessor.get(t.value.lower(), 'ID')

    return t


def t_preproc_NEWLINE(t):
    r'\r?\n'
    t.lexer.begin('INITIAL')
    t.lexer.lineno += len(t.value)

    return t


def t_preproc_INTEGER(t):
    r'[0-9]+'

    return t


def t_preproc_STRING(t):
    r'"[^"]*"'
    t.value = t.value[1:-1]  # Strip quotes

    return t


def t_preproc_LP(t):
    r'\('

    return t


def t_preproc_RP(t):
    r'\)'

    return t


def t_preproc_EQ(t):
    r'='

    return t


# tokens regexp. patterns
def t_ID(t):
    r'[a-zA-Z][a-zA-Z0-9]*[$%]?'
    t.type = reserved.get(t.value.lower(), 'ID')

    if t.type != 'ID':
        t.value = t.type

    if t.type == 'BIN':
        t.lexer.begin('bin')
        return None

    return t


def t_HEXA(t):
    r'([0-9][0-9a-fA-F]*[hH])|(\$[0-9a-fA-F]+)|(0x[0-9a-fA-F]+)'
    if t.value[0] == '$':
        t.value = t.value[1:]  # Remove initial '$'
    elif t.value[:2] == '0x':
        t.value = t.value[2:]  # Remove initial '0x'
    else:
        t.value = t.value[:-1]  # Remove last 'h'

    t.value = int(t.value, 16)  # Convert to decimal
    t.type = 'NUMBER'

    return t


def t_OCTAL(t):
    r'[0-7]+[oO]'
    t.value = t.value[:-1]
    t.type = 'NUMBER'
    t.value = int(t.value, 8)

    return t


def t_BIN(t):
    r'(%[01]+)|([01]+[bB])'  # A Binary integer
    # Note 00B is a 0 binary, but
    # 00Bh is a 12 in hex. So this pattern must come
    # after HEXA

    if t.value[0] == '%':
        t.value = t.value[1:]  # Remove initial %
    else:
        t.value = t.value[:-1]  # Remove last 'b'

    t.value = int(t.value, 2)  # Convert to decimal
    t.type = 'NUMBER'

    return t


def t_bin_NUMBER(t):
    r'[01]+'  # A binary integer
    t.value = int(t.value, 2)
    t.lexer.begin('INITIAL')

    return t


def t_NUMBER(t):
    # This pattern must come AFTER t_HEXA and t_BIN
    r'(([0-9]+(\.[0-9]+)?)|(\.[0-9]+))([eE][-+]?[0-9]+)?'
    t.text = t.value
    t.value = float(t.value)

    if t.value == int(t.value) and is_label(t):
        t.value = int(t.value)
        t.type = 'LABEL'

    return t


def t_INITIAL_bin_LineContinue(t):
    r"[_\\][ \t]*('.*|[Rr][Ee][Mm]\b.*|[Rr][Ee][Mm])?\r?\n"
    global LABELS_ALLOWED

    t.lexer.lineno += 1
    LABELS_ALLOWED = False


# track line numbers
def t_INITIAL_bin_NEWLINE(t):
    r'\r?\n'
    global LABELS_ALLOWED

    t.lexer.lineno += 1
    LABELS_ALLOWED = True
    return t


# Separator skipped
def t_INITIAL_bin_preproc_SEPARATOR(t):
    r'[ \t]+'
    pass


# error handling rule
def t_INITIAL_bin_string_asm_preproc_comment_error(t):
    syntax_error(t.lineno, "illegal character '%s'" % t.value[0])
    sys.exit(1)


# --------- END OF Token rules ---------

def find_column(token):
    """ Compute column:
            input is the input text string
            token is a token instance
    """
    i = token.lexpos
    input = token.lexer.lexdata

    while i > 0:
        if input[i - 1] == '\n': break
        i -= 1

    column = token.lexpos - i + 1

    return column


def is_label(token):
    """ Return whether the token is a label (an integer number or id
    at the beginning of a line.

    To do so, we compute find_column() and moves back to the beginning
    of the line if previous chars are spaces or tabs. If column 0 is
    reached, it's a label.
    """
    if not LABELS_ALLOWED:
        return False

    c = i = token.lexpos
    input = token.lexer.lexdata
    c -= 1
    while c > 0 and input[c] in (' ', '\t'):
        c -= 1

    while i > 0:
        if input[i] == '\n': break
        i -= 1

    column = c - i

    if column == 0:
        column += 1

    return column == 1


lexer = lex.lex(lextab='parsetab.zxblextab')

if __name__ == '__main__':  # For testing purposes
    import sys

    lexer.input(open(sys.argv[1], 'rt').read())

    while 1:
        tok = lexer.token()
        if not tok:
            break
        print(tok)
