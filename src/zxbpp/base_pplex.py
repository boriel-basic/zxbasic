#!/usr/bin/python3
# -*- coding: utf-8 -*-

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Lexer for the ZXBppASM (ZXBASM Preprocessor)
# ----------------------------------------------------------------------

import sys
from dataclasses import dataclass

from typing import Iterable
from typing import List
from typing import Optional
from typing import Tuple

from src.ply import lex
import src.api.utils
from src.zxbpp.prepro.output import warning, error

from .prepro.definestable import DefinesTable
from .prepro.builtinmacro import BuiltinMacro

EOL = '\n'

# Names for std input/output
STDOUT = '<stdout>'
STDIN = '<stdin>'
STDERR = '<stderr>'


@dataclass
class LexerState:
    filename: str
    lineno: int
    lex: Optional[lex.Lexer]
    input_data: str


class BaseLexer:
    """ Own class lexer to allow multiple instances.
    This lexer is just a wrapper of the current FILESTACK[-1] lexer
    It's the base class for the asm and basic preprocessor lexers.
    """
    builtin_macros = {
        '__FILE__': lambda token: f'"{token.fname}"',
        '__LINE__': lambda token: str(token.lineno)
    }

    def __init__(self,
                 tokens: Iterable[str],
                 states: Iterable[Tuple[str, str]],
                 defines_table: Optional[DefinesTable] = None
                 ):
        """ Creates a new GLOBAL lexer instance
        """
        self.lex: Optional[lex.Lexer] = None
        self.filestack: List[LexerState] = []  # Current filename, and line number being parsed
        self.input_data: str = ''
        self.tokens = tuple(tokens)
        self.states = tuple(states)
        self.next_token = None  # if set to something, this will be returned once
        self.defines_table = defines_table

        if defines_table is None:
            return

        for macro_name, macro_func in self.builtin_macros.items():
            self.defines_table[macro_name] = BuiltinMacro(
                macro_name=macro_name, func=macro_func
            )

    def put_current_line(self, prefix: str = '', suffix: str = '') -> str:
        """ Returns line and file for include / end of include sequences.
        """
        assert self.lex is not None
        return '%s#line %i "%s"%s' % (prefix, self.lex.lineno, self.filestack[-1].filename, suffix)

    def include(self, filename: str) -> str:
        """ Changes FILENAME and line count
        """
        if filename != STDIN and filename in set(x.filename for x in self.filestack):  # Already included?
            self.warning('Recursive inclusion')

        self.filestack.append(LexerState(filename, 1, self.lex, self.input_data))

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
                self.input_data = src.api.utils.read_txt_file(filename)
            if len(self.input_data) and self.input_data[-1] != EOL:
                self.input_data += EOL
        except IOError:
            self.input_data = EOL

        self.lex.input(self.input_data)
        return result

    def include_end(self):
        """ Performs and end of include.
        """
        old_lineno = self.lex.lineno
        old_lexpos = self.lex.lexpos
        self.lex = self.filestack[-1].lex
        self.input_data = self.filestack[-1].input_data
        self.filestack.pop()

        if not self.filestack:  # End of input?
            return None

        self.filestack[-1].lineno += 1  # Increment line counter of previous file

        result = lex.LexToken()  # create token
        result.value = self.put_current_line(suffix='\n')
        result.type = '_ENDFILE_'
        result.lineno = old_lineno
        result.lexpos = old_lexpos
        result.fname = self.current_file

        return result

    def input(self, str_: str, filename: str = '', lexpos: int = 0):
        """ Defines input string, removing current lexer.
        """
        self.filestack.append(LexerState(filename, 1, self.lex, self.input_data))
        self.input_data = str_
        self.set_state(str_, lexpos)

    def set_state(self, new_input: str, new_lexpos: int = 0):
        self.lex = lex.lex(object=self)
        self.lex.input(new_input)
        self.lexpos = new_lexpos

    @property
    def lexpos(self) -> int:
        if self.lex is None:
            return 0

        return self.lex.lexpos

    @lexpos.setter
    def lexpos(self, value: int):
        assert self.lex is not None
        self.lex.lexpos = value

    @property
    def lineno(self) -> int:
        if self.lex is None:
            return 0

        return self.lex.lineno

    def token(self) -> Optional[lex.LexToken]:
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
            tok.fname = self.current_file
            self.next_token = None

        while self.lex is not None and tok is None:
            tok = self.lex.token()
            if tok is not None:
                tok.fname = self.current_file
                break

            tok = self.include_end()

        return tok

    def find_column(self, token) -> int:
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

    def error(self, msg: str, lineno: int = None):
        """ Prints an error msg and continues execution.
        """
        if lineno is None:
            lineno = self.lineno
        error(lineno, msg)

    def warning(self, msg: str, lineno: int = None):
        """ Emits a warning and continue execution.
        """
        if lineno is None:
            lineno = self.lineno
        warning(lineno, msg)

    @property
    def current_file(self) -> Optional[str]:
        if not self.filestack:
            return None

        return self.filestack[-1].filename
