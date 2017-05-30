#!/usr/bin/env python
# -*- coding: utf-8 -*-

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Lexer for the ZXBpp (ZXBasic Preprocessor)
# ----------------------------------------------------------------------

import os
import sys
from ply import lex
from prepro.output import warning, error
import api.utils

EOL = '\n'

# Names for std input/output
STDOUT = '<stdout>'
STDIN = '<stdin>'
STDERR = '<stderr>'

states = (
    ('prepro', 'exclusive'),
    ('define', 'exclusive'),
    ('defargsopt', 'exclusive'),
    ('defargs', 'exclusive'),
    ('defexpr', 'exclusive'),
    ('pragma', 'exclusive'),
    ('singlecomment', 'exclusive'),
    ('comment', 'exclusive'),
    ('asm', 'exclusive'),
    ('asmcomment', 'exclusive'),
    ('if', 'exclusive')
)

_tokens = ('STRING', 'TOKEN', 'NEWLINE', '_ENDFILE_', 'FILENAME', 'ID',
           'INTEGER', 'EQ', 'PUSH', 'POP', 'LP', 'LLP', 'RRP', 'RP', 'COMMA',
           'CONTINUE', 'NUMBER', 'SEPARATOR', 'GT', 'GE', 'LT', 'LE', 'NE'
           )

reserved_directives = {
    'include': 'INCLUDE',
    'once': 'ONCE',
    'define': 'DEFINE',
    'undef': 'UNDEF',
    'if': 'IF',
    'ifdef': 'IFDEF',
    'ifndef': 'IFNDEF',
    'else': 'ELSE',
    'endif': 'ENDIF',
    'init': 'INIT',
    'line': 'LINE',
    'require': 'REQUIRE',
    'pragma': 'PRAGMA',
}

# List of token names.
tokens = sorted(_tokens + tuple(reserved_directives.values()))


class Lexer(object):
    """ Own class lexer to allow multiple instances.
    This lexer is just a wrapper of the current FILESTACK[-1] lexer
    """

    # -------------- TOKEN ACTIONS --------------
    def t_INITIAL_COMMENT(self, t):
        r"(\b[Rr][Ee][Mm]\b)|'"
        t.lexer.push_state('singlecomment')

    def t_INITIAL_asmBegin(self, t):
        r'\b[aA][sS][mM]\b'
        t.type = 'TOKEN'
        t.lexer.begin('asm')

        return t

    def t_asm_asmEnd(self, t):
        r'\b[Ee][Nn][Dd][ \t]+[Aa][Ss][Mm]\b'
        t.type = 'TOKEN'
        t.lexer.begin('INITIAL')

        return t

    def t_asm_CONTINUE(self, t):
        r'[\\_]([ \t]*;.*)?\r?\n'
        t.lexer.lineno += 1

        return t

    def t_asm_COMMENT(self, t):
        r';'
        t.lexer.push_state('asmcomment')

    def t_asmcomment_skip(self, t):
        r'.'
        pass

    def t_asmcomment_NEWLINE(self, t):
        r'\r?\n'
        # New line => remove whatever state in top of the stack and replace it with INITIAL
        t.lexer.lineno += 1
        t.lexer.pop_state()

        return t

    def t_asm_NEWLINE(self, t):
        r'\r?\n'
        # New line => remove whatever state in top of the stack and replace it with INITIAL
        t.lexer.lineno += 1

        return t

    def t_asm_ID(self, t):
        r'[_A-Za-z][_A-Za-z0-9]*'

        return t

    def t_asm_CHAR(self, t):
        r"'([^'\n]|'')'"
        t.type = 'TOKEN'

        return t

    def t_asm_TOKEN(self, t):
        r"[][',.:$()*/+-]"

        return t

    def t_INITIAL_ID(self, t):
        r'[_a-zA-Z][_a-zA-Z0-9]*[$%]?'

        return t

    def t_prepro_define_defargs_defargsopt_defexpr_pragma_if_NEWLINE(self, t):
        r'\r?\n'
        t.lexer.lineno += 1
        t.lexer.pop_state()

        return t

    def t_INITIAL_NEWLINE(self, t):
        r'\r?\n'
        t.lexer.lineno += 1

        return t

    def t_prepro_define_defargs_defargsopt_defexpr_pragma_COMMENT(self, t):
        r"'"
        t.lexer.begin('singlecomment')

    def t_singlecomment_NEWLINE(self, t):
        r'\r?\n'
        t.lexer.pop_state()  # Back to initial
        t.lexer.lineno += 1

        return t

    def t_singlecomment_prepro_define_pragma_defargs_defargsopt_CONTINUE(self, t):
        r'[_\\]\r?\n'
        t.lexer.lineno += 1
        t.value = t.value[1:]
        t.type = 'NEWLINE'

        return t

    def t_INITIAL_comment_beginBlock(self, t):
        r"/'"
        self.__COMMENT_LEVEL += 1
        t.lexer.begin('comment')

    def t_comment_NEWLINE(self, t):
        r'\r?\n'
        t.lexer.lineno += 1

        return t

    def t_comment_endBlock(self, t):
        r"'/"
        self.__COMMENT_LEVEL -= 1
        if not self.__COMMENT_LEVEL:
            t.lexer.begin('INITIAL')

    # Any other character is ignored until EOL
    def t_singlecomment_comment_Skip(self, t):
        r'.'
        pass

    # Allows line breaking
    def t_defexpr_CONTINUE(self, t):
        r'[\\_]\r?\n'
        t.lexer.lineno += 1
        t.value = t.value[1:]

        return t

    def t_prepro_pragma_defargs_define_if_skip(self, t):
        r'[ \t]+'
        pass  # Ignore whitespaces and tabs

    def t_if_EQ(self, t):
        r'=='

        return t

    def t_if_NE(self, t):
        r'!=|<>'

        return t

    def t_if_GE(self, t):
        r'>='

        return t

    def t_if_GT(self, t):
        r'>'

        return t

    def t_if_LE(self, t):
        r'<='

        return t

    def t_if_LT(self, t):
        r'<'

        return t

    def t_prepro_ID(self, t):
        r'[_a-zA-Z][_a-zA-Z0-9]*'  # preprocessor directives
        t.type = reserved_directives.get(t.value.lower(), 'ID')
        if t.type == 'DEFINE':
            t.lexer.begin('define')

        if t.type == 'PRAGMA':
            t.lexer.begin('pragma')

        if t.type == 'IF':
            t.lexer.begin('if')

        if t.type == 'ID' and self.expectingDirective:
            self.error("invalid directive #%s" % t.value)

        self.expectingDirective = False

        return t

    def t_pragma_LP(self, t):
        r'\('

        return t

    def t_pragma_RP(self, t):
        r'\)'

        return t

    def t_INITIAL_defexpr_if_LLP(self, t):
        r'\('

        return t

    def t_INITIAL_defexpr_if_RRP(self, t):
        r'\)'

        return t

    def t_pragma_ID(self, t):
        r'[_a-zA-Z][_a-zA-Z0-9]*'  # pragma directives
        if t.value.upper() in ('PUSH', 'POP'):
            t.type = t.value.upper()

        return t

    def t_defargsopt_LP(self, t):
        r'\('
        t.lexer.begin('defargs')

        return t

    # Any other char than '(' means no arglist
    def t_defargsopt_TOKEN(self, t):
        r'[ \t)@,{}:;.+*/!|&~$-]|=>|<=|<>|=|<|>'
        t.lexer.begin('defexpr')

        return t

    def t_defargsopt_STRING(self, t):
        r'"([^"\n]|"")*"'  # a doubled quoted string
        t.lexer.begin('defexpr')

        return t

    def t_defargs_LP(self, t):
        r'\('

        return t

    def t_defargs_RP(self, t):
        r'\)'
        t.lexer.begin('defexpr')

        return t

    def t_defargsopt_defexpr_ID(self, t):
        r'[_a-zA-Z][_a-zA-Z0-9]*'  # preprocessor directives
        t.lexer.begin('defexpr')

        return t

    def t_defargsopt_SEPARATOR(self, t):
        r'[ \t]+'
        t.lexer.begin('defexpr')

    def t_defargs_if_ID(self, t):
        r'[_a-zA-Z][_a-zA-Z0-9]*'  # preprocessor directives

        return t

    def t_define_ID(self, t):
        r'[_a-zA-Z][_a-zA-Z0-9]*'  # preprocessor directives
        t.lexer.begin('defargsopt')

        return t

    def t_prepro_pragma_INTEGER(self, t):
        r'[0-9]+'  # an integer number

        return t

    def t_prepro_pragma_STRING(self, t):
        r'"([^"\n]|"")*"'  # a doubled quoted string
        t.value = t.value[1:-1]  # Remove quotes

        return t

    def t_INITIAL_defexpr_asm_STRING(self, t):
        r'"([^"\n]|"")*"'  # a doubled quoted string

        return t

    def t_pragma_EQ(self, t):
        r'='

        return t

    def t_INITIAL_defexpr_defargs_prepro_COMMA(self, t):
        r','

        return t

    def t_INITIAL_asm_sharp(self, t):
        r'[ \t]*\#'  # Only matches if at beginning of line and "#"
        if self.find_column(t) == 1:
            t.lexer.push_state('prepro')  # Start preprocessor
            self.expectingDirective = True

    def t_INITIAL_defexpr_TOKEN(self, t):
        r'=>|<=|>=|<>|[$!&|~@:;{}.<>^=+*/%-]'

        return t

    def t_INITIAL_CONTINUE(self, t):
        r'[\\_]\r?\n'
        t.lexer.lineno += 1

        return t

    def t_INITIAL_defexpr_asm_SEPARATOR(self, t):
        r'[ \t]+'

        return t

    def t_INITIAL_defexpr_asm_HEXA(self, t):
        r'([0-9][0-9a-fA-F]*[hH])|(\$[0-9a-fA-F]+)'
        # Hexadecimal numbers
        t.type = 'NUMBER'

        return t

    def t_INITIAL_defexpr_asm_BIN(self, t):
        r'(%[01]+)|([01]+[bB])'  # A Binary integer
        # Note 00B is a 0 binary, but
        # 00Bh is a 12 in hex. So this pattern must come
        # after HEXA
        t.type = 'NUMBER'

        return t

    def t_INITIAL_defexpr_asm_if_NUMBER(self, t):
        # This pattern must come AFTER t_HEXA and t_BIN
        r'(([0-9]+(\.[0-9]+)?)|(\.[0-9]+))([eE][-+]?[0-9]+)?'

        return t

    def t_prepro_FILENAME(self, t):
        r'<[^>]*>'
        t.value = t.value[1:-1]  # Remove quotes

        return t

    def t_INITIAL_defargs_defargsopt_prepro_define_defexpr_pragma_comment_singlecomment_asm_asmcomment_if_error(self,
                                                                                                                t):
        """ error handling rule
        """
        self.error("illegal preprocessor character '%s'" % t.value[0])

    def put_current_line(self, prefix='', suffix=''):
        """ Returns line and file for include / end of include sequences.
        """
        return '%s#line %i "%s"%s' % (prefix, self.lex.lineno, os.path.basename(self.filestack[-1][0]), suffix)

    def include(self, filename):
        """ Changes FILENAME and line count
        """
        if filename != STDIN and filename in [x[0] for x in self.filestack]:  # Already included?
            self.warning(filename + ' Recursive inclusion')

        self.filestack.append([filename, 1, self.lex, self.input_data])

        if self.lex is None:
            self.lex = lex.lex(object=self)
        else:
            self.lex = self.lex.clone()
            self.lex.lineno = 1  # resets line number

        result = self.put_current_line()  # First #line start with \n (EOL)

        try:
            if filename == STDIN:
                self.input_data = sys.stdin.read()
            else:
                self.input_data = api.utils.read_txt_file(filename)
            if len(self.input_data) and self.input_data[-1] != EOL:
                self.input_data += EOL

            self.lex.input(self.input_data)
        except IOError:
            self.error('cannot open "%s" file' % filename)

        return result

    def include_end(self):
        """ Performs and end of include.
        """
        self.lex = self.filestack[-1][2]
        self.input_data = self.filestack[-1][3]
        self.filestack.pop()

        if not self.filestack:  # End of input?
            return

        self.filestack[-1][1] += 1  # Increment line counter of previous file

        result = lex.LexToken()
        result.value = self.put_current_line(suffix='\n')
        result.type = '_ENDFILE_'
        result.lineno = self.lex.lineno
        result.lexpos = self.lex.lexpos

        return result

    def input(self, str, filename=''):
        """ Defines input string, removing current lexer.
        """
        self.filestack.append([filename, 1, self.lex, self.input_data])

        self.input_data = str
        self.lex = lex.lex(object=self)
        self.lex.input(self.input_data)

    def token(self):
        """ Returns a token from the current input. If tok is None
        from the current input, it means we are at end of current input
        (e.g. at end of include file). If so, closes the current input
        and discards it; then pops the previous input and lexer from
        the input stack, and gets another token.

        If new token is again None, repeat the process described above
        until the token is either not None, or self.lex is None, wich
        means we must effectively return None, because parsing has
        ended.
        """
        tok = None
        if self.next_token is not None:
            tok = lex.LexToken()
            tok.value = ''
            tok.lineno = self.lex.lineno
            tok.lexpos = self.lex.lexpos
            tok.type = self.next_token
            self.next_token = None

        while self.lex is not None and tok is None:
            tok = self.lex.token()
            if tok is not None:
                break

            tok = self.include_end()

        return tok

    def find_column(self, token):
        """ Compute column:
                - token is a token instance
        """
        i = token.lexpos
        while i > 0:
            if self.input_data[i - 1] == '\n':
                break
            i -= 1

        column = token.lexpos - i + 1
        return column

    def error(self, msg):
        """ Prints an error msg, and exits.
        """
        error(self.lex.lineno, msg)
        sys.exit(1)

    def warning(self, msg):
        """ Emits a warning and continue execution.
        """
        warning(self.lex.lineno, msg)

    def __init__(self):
        """ Creates a new GLOBAL lexer instance
        """
        self.lex = None
        self.filestack = []  # Current filename, and line number being parsed
        self.input_data = ''
        self.tokens = tokens
        self.states = states
        self.next_token = None  # if set to something, this will be returned once
        self.expectingDirective = False  # True if the lexer expects a preprocessor directive
        self.__COMMENT_LEVEL = 0


# --------------------- PREPROCESOR FUNCTIONS -------------------

# Needed for states
tmp = lex.lex(object=Lexer(), lextab='parsetab.zxbpplextab')

# ------------------ Test if called from cmd line ---------------
if __name__ == '__main__':  # For testing purposes
    lexer = Lexer()
    lexer.include(sys.argv[1])

    while 1:
        tok = lexer.token()
        if not tok:
            break
        print(tok)
