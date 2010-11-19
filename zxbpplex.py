#!/usr/bin/python
# -*- coding: utf-8 -*-

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Lexer for the ZXBpp (ZXBasic Preprocessor)
# ----------------------------------------------------------------------

import ply.lex as lex
import sys, os

EOL = '\n'

states = (
		('prepro', 'exclusive'),
		('define', 'exclusive'),
		('defexpr', 'exclusive'),
		('pragma', 'exclusive'),
	)

_tokens = ('STRING', 'CHAR', 'NEWLINE', '_ENDFILE_', 'FILENAME', 'ID',
		'INTEGER', 'EQ', 'PUSH', 'POP', 'LP', 'RP',
	)

reserved_directives = {
	'include' : 'INCLUDE',
	'once'	: 'ONCE',
	'define' : 'DEFINE',
	'undef' : 'UNDEF',
	'ifdef' : 'IFDEF',
	'ifndef' : 'IFNDEF',
	'else' : 'ELSE',
	'endif': 'ENDIF',
	'init' : 'INIT',
	'line' : 'LINE',
	'require': 'REQUIRE',
	'pragma': 'PRAGMA',
	}

# List of token names.
tokens = _tokens + tuple(reserved_directives.values())

ID_TABLE = None


class Lexer(object):
	''' Own class lexer to allow multiple instances.
	This lexer is just a wrapper of the current FILESTACK[-1] lexer
	'''

	# -------------- TOKEN ACTIONS --------------

	def t_INITIAL_ID(self, t):
		r'[_a-zA-Z][_a-zA-Z0-9]*' # preprocessor directives
		t.type = 'CHAR' # Mark is as normal char
		t.value = ID_TABLE.value(t.value) # Try macro substitution
	
		return t


	def t_INITIAL_prepro_define_defexpr_pragma_NEWLINE(self, t):
		r'\r?\n'
		t.lexer.lineno += len(t.value)
		t.lexer.begin('INITIAL')

		return t


	# Allows line breaking
	def t_prepro_define_defexpr_CONTINUE(self, t):
		r'\\\r?\n'
		t.lexer.lineno += 1
		t.type = 'CHAR'
		t.value = t.value[1:]

		return t
	
	
	def t_prepro_pragma_define_skip(self, t):
		r'[ \t]+'
		pass	# Ignore whitespaces and tabs

	
	def t_prepro_ID(self, t):
		r'[_a-zA-Z][_a-zA-Z0-9]*' # preprocessor directives
		t.type = reserved_directives.get(t.value.lower(), 'ID')
		if t.type == 'DEFINE':
			t.lexer.begin('define')

		if t.type == 'PRAGMA':
			t.lexer.begin('pragma')
	
		return t


	def t_pragma_LP(self, t):
		r'\('

		return t


	def t_pragma_RP(self, t):
		r'\)'

		return t


	def t_pragma_ID(self, t):
		r'[_a-zA-Z][_a-zA-Z0-9]*' # pragma directives
		if t.value.upper() in ('PUSH', 'POP'):
			t.type = t.value.upper()
	
		return t

	
	def t_defexpr_ID(self, t):
		r'[_a-zA-Z][_a-zA-Z0-9]*' # preprocessor directives
	
		return t


	def t_define_ID(self, t):
		r'[_a-zA-Z][_a-zA-Z0-9]*[ \t]*' # preprocessor directives
		t.lexer.begin('defexpr')
		t.value = t.value.strip()	# Removes tabs and spaces
	
		return t


	def t_prepro_pragma_INTEGER(self, t):
		r'[0-9]+' # an integer number
		
		return t
		
	
	def t_prepro_pragma_STRING(self, t):
		r'"[^"]*"' # a doubled quoted string
		t.value = t.value[1:-1] # Remove quotes
	
		return t


	def t_INITIAL_defexpr_STRING(self, t):
		r'"[^"]*"' # a doubled quoted string
		t.type = 'CHAR'
	
		return t


	def t_pragma_EQ(self, t):
		r'='

		return t


	def t_defexpr_CHAR(self, t):
		r'.'

		return t


	def t_INITIAL_CHAR(self, t):
		r'.'	# Only matches if at beginning of line and "#"
		if t.value == '#' and self.find_column(t) == 1:
			t.lexer.begin('prepro') # Start preprocessor
		else:
			return t
	

	def t_prepro_FILENAME(self, t):
		r'<[^>]*>'
		t.value = t.value[1:-1] # Remove quotes
	
		return t


	def t_INITIAL_prepro_define_defexpr_pragma_error(self, t):
		''' error handling rule
		'''
		self.error("illegal preprocessor character '%s'" % t.value[0])


	def __init__(self):
		''' Creates a new GLOBAL lexer instance
		'''
		self.lex = None
		self.filestack = [] # Current filename, and line number being parsed
		self.input_data = ''
		self.tokens = tokens
		self.states = states
		self.next_token = None # if set to something, this will be returned once


	def put_current_line(self):
		''' Returns line and file for include / end of include sequences.
		'''
		return '#line %i "%s"\n' % (self.lex.lineno, os.path.basename(self.filestack[-1][0]))


	def include(self, filename):
		''' Changes FILENAME and line count
		'''
		if filename in [x[0] for x in self.filestack]: # Already included?
			self.warning(filename + ' Recursive inclusion')
	
		self.filestack.append([filename, 1, self.lex, self.input_data])
		self.lex = lex.lex(object = self)
		result = self.put_current_line()
		try:
			self.input_data = open(filename, 'rt').read()
			if len(self.input_data) and self.input_data[-1] != EOL:
				self.input_data += EOL
				
			self.lex.input(self.input_data)
		except IOError:
			self.error('cannot open "%s" file' % filename)

		return result


	def include_end(self):
		''' Performs and end of include.
		'''
		self.lex = self.filestack[-1][2]
		self.input_data = self.filestack[-1][3]
		self.filestack.pop()
	
		if self.filestack == []: # End of input?
			return
	
		self.filestack[-1][1] += 1 # Increment line counter of previous file

		result = lex.LexToken()
		result.value = self.put_current_line()
		result.type = '_ENDFILE_'
		result.lineno = self.lex.lineno
		result.lexpos = self.lex.lexpos

		return result	


	def input(self, str, filename = ''):
		''' Defines input string, removing current lexer.
		'''
		self.filestack.append([filename, 1, self.lex, self.input_data])

		self.input_data = str
		self.lex = lex.lex(object = self)
		self.lex.input(self.input_data)
	

	def token(self):
		''' Returns a token from the current input. If tok is None
		from the current input, it means we are at end of current input
		(e.g. at end of include file). If so, closes the current input
		and discards it; then pops the previous input and lexer from
		the input stack, and gets another token.
		
		If new token is again None, repeat the process described above
		until the token is either not None, or self.lex is None, wich
		means we must effectively return None, because parsing has
		ended.
		'''
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
			if tok is not None: break

			tok = self.include_end()

		return tok	
			
		
	def find_column(self, token):
		''' Compute column:
				- token is a token instance
		'''
		i = token.lexpos
		while i > 0:
		    if self.input_data[i - 1] == '\n': break
		    i -= 1
	
		column = token.lexpos - i + 1

		return column


	def msg(self, str):
		''' Prints an error msg.
		'''
		fname = os.path.basename(self.filestack[-1][0])
		line = self.filestack[-1][1]
	
		print '%s:%i %s' % (fname, line, str)
	
	
	def error(self, str):
		''' Prints an error msg, and exits.
		'''
		self.msg('Error: %s' % str)
	
		sys.exit(1)
	
	
	def warning(self, str):
		''' Emmits a warning and continue execution.
		'''
		self.msg('Warning: %s' % str)


# --------------------- PREPROCESOR FUNCTIONS -------------------

# Needed for states 
tmp = lex.lex(object = Lexer(), lextab = 'zxbpplextab')

