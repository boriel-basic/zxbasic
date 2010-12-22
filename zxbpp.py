#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et:

# ----------------------------------------------------------------------
# Copyleft (K), Jose M. Rodriguez-Rosa (a.k.a. Boriel)
#
# This program is Free Software and is released under the terms of
#                    the GNU General License
#
# This is the Parser for the ZXBpp (ZXBasic Preprocessor)
# ----------------------------------------------------------------------

import sys, os
import zxbpplex
import ply.yacc as yacc

from zxbpplex import tokens
from common import OPTIONS

OPTIONS.add_option_if_not_defined('Sinclair', bool, False)

OUTPUT = ''
INCLUDED = {}    # Already included files (with lines)
CURRENT_FILE = []    # Current file being processed
LEXER = zxbpplex.Lexer()

# CURRENT working directory for this cpp

def get_include_path():
    ''' Default include path using a tricky sys
    calls.
    '''
    f1 = os.path.basename(sys.argv[0]).lower() # script filename
    f2 = os.path.basename(sys.executable).lower() # Executable filename

    if f1 == f2 or f2 == f1 + '.exe': # If executable filename and scriptname are the same, we are
        result = os.path.dirname(os.path.realpath(sys.executable)) # under a "compiled" py2exe binary
    else:
        result = os.path.dirname(os.path.realpath(sys.argv[0]))

    return result


CURRENT_DIR = get_include_path()

# Default include path
INCLUDEPATH = ('library', 'library-asm')

# Symbol Table (must be an instance of DefinesTable)
ID_TABLE = zxbpplex.ID_TABLE

# Enabled to FALSE if IFDEF failed
ENABLED = True


#IFDEFS array
IFDEFS = [] # Push (Line, state here)


class ID(object):
    ''' This class just stores a string
    '''
    def __init__(self, id, args, value, lineno, fname):
        self.name = id 
        self.value = value
        self.lineno = lineno # line number at which de ID was defined
        self.fname = fname # file name in which the ID was defined
        self.args = args


class DefinesTable(object):
    ''' A class which will store
    define labels, and its values.
    It will also susbtitute the current value
    of a label for the given value.
    '''
    def __init__(self):
        ''' Initializes table
        '''
        self.table = {}


    def define(self, id, lineno, value = '', fname = None, args = None):
        if fname is None:
            if CURRENT_FILE:
                fname = CURRENT_FILE[-1]
            else: # If no files opened yet, use owns program fname
                fname = sys.argv[0]

        if self.defined(id):
            i = self.table[id]            
            warning(lineno, '"%s" redefined (previous definition at %s:%i)' % (i.name, i.fname, i.lineno))
        self.table[id] = ID(id, args, value, lineno, fname)


    def undef(self, id):
        if self.defined(id):
            del self.table[id]


    def value(self, id):
        ''' Returns value of ID,
        recursively evalued
        '''

        ''' If id not in table, its value is the 
        id itself'''
        if not self.defined(id):
            return id

        result = ''

        for i in self.table[id].value:
            if isinstance(i, ID):
                result += self.value(i.value)
            else:
                result += i

        return result


    def defined(self, id):
        ''' Returns if the given ID 
        is defined
        '''
        return id in self.table.keys()



def search_filename(fname, lineno):
    ''' Search a filename into the list of the include path
    '''
    for i in INCLUDEPATH:
        if not os.path.isabs(i):
            for j in os.environ['PATH'].split(os.pathsep) + [CURRENT_DIR]:
                path = os.path.join(j, i, fname)
                if os.path.exists(path):
                    return path
        else:
            path = os.path.join(i, fname)
            if os.path.exists(path):
                return path

    error(lineno, "file '%s' not found" % fname)
        


def include_file(filename, lineno):
    ''' Writes down that "filename" was included at the current file, 
    at line <lineno>
    '''

    if filename not in INCLUDED.keys():
        INCLUDED[filename] = []

    if len(CURRENT_FILE) > 0:
        INCLUDED[filename].append((CURRENT_FILE[-1], lineno)) # Added from wich file, line

    CURRENT_FILE.append(filename)

    return LEXER.include(filename)



def include_once(filename, lineno):
    ''' Do as above only in file not already included
    '''
    if filename not in INCLUDED.keys(): # If not already included 
        return include_file(filename, lineno) # include it and return

    # Now checks if the file has been included more than once
    if len(INCLUDED[filename]) > 1:
        warning(lineno, "file '%s' already included more than once, in file '%s' at line %i" % 
            (filename, INCLUDED[filename][0][0], INCLUDED[filename][0][1]))

    return ''
    


# -------- GRAMMAR RULES for the preprocessor ---------
def p_start(p):
    ''' start : program 
    '''
    global OUTPUT

    OUTPUT += p[1]


def p_program(p):
    ''' program : CHAR
                | NEWLINE
                | include_file
                | line
                | init
                | define NEWLINE
                | undef NEWLINE
                | ifdef NEWLINE
                | require
                | pragma
    '''
    p[0] = p[1]


def p_program_char(p):
    ''' program : program CHAR
                | program NEWLINE
                | program include_file
                | program line
                | program init
                | program define NEWLINE
                | program undef NEWLINE
                | program ifdef NEWLINE
                | program require
                | program pragma
    '''
    p[0] = p[1] + p[2]


def p_include_file(p):
    ''' include_file : include NEWLINE program _ENDFILE_
    '''
    p[0] = p[1] + p[3] + p[4]
    CURRENT_FILE.pop() # Remove top of the stack


def p_include_file_empty(p):
    ''' include_file : include NEWLINE _ENDFILE_
    ''' # This happens when an IFDEF is FALSE
    p[0] = ''


def p_include_once_empty(p):
    ''' include_file : include_once NEWLINE _ENDFILE_
    '''
    p[0] = '' # Include once already included. Nothing done.


def p_include_once_ok(p):
    ''' include_file : include_once NEWLINE program _ENDFILE_
    '''
    p[0] = p[1] + p[3] + p[4]
    CURRENT_FILE.pop() # Remove top of the stack


def p_include(p):
    ''' include : INCLUDE STRING 
    '''
    if ENABLED:
        p[0] = include_file(p[2], p.lineno(2))
    else:
        p[0] = ''
        p.lexer.next_token = '_ENDFILE_'


def p_include_fname(p):
    ''' include : INCLUDE FILENAME
    '''
    if ENABLED:
        l = p.lineno(2)
        p[0] = include_file(search_filename(p[2], l), l)
    else:
        p[0] = ''
        p.lexer.next_token = '_ENDFILE_'


def p_include_once(p):
    ''' include_once : INCLUDE ONCE STRING
    '''
    if ENABLED:
        p[0] = include_once(p[3], p.lineno(3))
    else:
        p[0] = ''

    if p[0] == '':
        p.lexer.next_token = '_ENDFILE_'


def p_include_once_fname(p):
    ''' include_once : INCLUDE ONCE FILENAME
    '''
    if ENABLED:
        l = p.lineno(3)
        p[0] = include_once(search_filename(p[3], l), l)
    else:
        p[0] = ''

    if p[0] == '':
        p.lexer.next_token = '_ENDFILE_'


def p_line(p):
    ''' line : LINE INTEGER NEWLINE
    '''
    if ENABLED:
        p[0] = '#%s %s\n' % (p[1], p[2])
    else:
        p[0] = '\n'


def p_line_file(p):
    ''' line : LINE INTEGER STRING NEWLINE
    '''
    if ENABLED:
        p[0] = '#%s %s "%s"\n' % (p[1], p[2], p[3])
    else:
        p[0] = '\n'


def p_require_file(p):
    ''' require : REQUIRE STRING NEWLINE
    '''
    p[0] = '#%s "%s"\n' % (p[1], p[2])


def p_init(p):
    ''' init : INIT ID NEWLINE
             | INIT STRING NEWLINE
    '''
    p[0] = '#%s %s\n' % (p[1], p[2])


def p_undef(p):
    ''' undef : UNDEF ID 
    '''
    if ENABLED:
        ID_TABLE.undef(p[2])

    p[0] = '\n'


def p_define(p):
    ''' define : DEFINE ID args expr_list 
    '''
    if ENABLED:
        ID_TABLE.define(p[2], args = p[3], value = p[4], lineno = p.lineno(2), fname = CURRENT_FILE[-1])

    p[0] = '\n'


def p_define_empty(p):
    ''' define : DEFINE ID args
    '''
    if ENABLED:
        ID_TABLE.define(p[2], args = p[3], lineno = p.lineno(2), value = '', fname = CURRENT_FILE[-1])

    p[0] = '\n'


def p_define_args_epsilon(p):
    ''' args :
    '''
    p[0] = None


def p_define_args_empty(p):
    ''' args : LP RP
    '''
    p[0] = []


def p_define_args_arglist(p):
    ''' args : LP arg_list RP
    '''
    for i in p[2]:
        if not isinstance(i, ID):
            error(p.lineno(3), '"%s" might not appear in a macro parameter list', str(i))
            p[0] = None
            return

    names = [x.name for x in p[2]]
    for i in range(len(names)):
        if names[i] in names[i:]:
            error(p.lineno(3), 'Duplicated name parameter "%s"' % (names[i]))
            p[0] = None
            return

    p[0] = p[2]


def p_arglist_single(p):
    ''' arg_list : ID
    '''
    p[0] = [ID(p[1], value = '', args = None, lineno = p.lineno(1), fname = CURRENT_FILE[-1])]
    

def p_arglist_arglist(p):
    ''' arg_list : arg_list COMMA ID
    '''
    p[0] = p[1] + [ID(p[3], value = '', args = None, lineno = p.lineno(1), fname = CURRENT_FILE[-1])]


def p_pragma_id(p):
    ''' pragma : PRAGMA ID
    '''
    p[0] = '#%s %s' % (p[1], p[2])


def p_pragma_id_expr(p):
    ''' pragma : PRAGMA ID EQ ID
               | PRAGMA ID EQ STRING
               | PRAGMA ID EQ INTEGER
    '''
    p[0] = '#%s %s %s %s' % (p[1], p[2], p[3], p[4])


def p_pragma_push(p):
    ''' pragma : PRAGMA PUSH LP ID RP
               | PRAGMA POP LP ID RP
    '''
    p[0] = '#%s %s%s%s%s' % (p[1], p[2], p[3], p[4], p[5])


def p_expr(p):
    ''' expr_list : expr
    '''
    p[0] = [p[1]]


def p_expr_list(p):
    ''' expr_list : expr_list expr
    '''
    p[0] = p[1]

    if isinstance(p[2], ID):
        p[0].append(p[2])
    elif len(p[0]) > 0 and not isinstance(p[0][-1], ID):
        p[0][-1] += p[2]
    else:
        p[0].append(p[2])


def p_expr_any(p):
    ''' expr : CHAR
    '''
    p[0] = p[1]


def p_expr_str(p):
    ''' expr : STRING
    '''
    p[0] = p[1]


def p_expr_id(p):
    ''' expr : ID
    '''
    p[0] = ID(p[1], args = None, value = '', lineno = p.lineno(1), fname = CURRENT_FILE[-1])


def p_ifdef(p):
    ''' ifdef : if_header NEWLINE program ENDIF 
    '''
    global ENABLED

    if ENABLED:
        p[0] = "\n%s" % p[3]
        p[0] += '#line %i "%s"\n' % (p.lineno(4) + 1, CURRENT_FILE[-1])
    else:
        p[0] = ''

    ENABLED = IFDEFS[-1][0]
    IFDEFS.pop()


def p_ifdef_else(p):
    ''' ifdef : if_header NEWLINE program ELSE program ENDIF 
    '''
    global ENABLED

    if ENABLED:
        p[0] = "\n%s" % p[3]
    else:
        p[0] = '#line %i "%s"' % (p.lineno(4), CURRENT_FILE[-1])
        p[0] += "\n%s" % p[5]

    p[0] += '#line %i "%s"\n' % (p.lineno(6) + 1, CURRENT_FILE[-1])
    ENABLED = IFDEFS[-1][0]
    IFDEFS.pop()

    
def p_if_header(p):
    ''' if_header : IFDEF ID
    '''
    global ENABLED

    IFDEFS.append((ENABLED, p.lineno(2)))
    ENABLED = ID_TABLE.defined(p[2])


def p_ifn_header(p):
    ''' if_header : IFNDEF ID
    '''
    global ENABLED

    IFDEFS.append((ENABLED, p.lineno(2)))
    ENABLED = not ID_TABLE.defined(p[2])
    
    

# --- YYERROR

def p_error(p):
    if p is not None:
        error(p.lineno, "syntax error. Unexpected token '%s' [%s]" % (p.value, p.type))
    else:
        OPTIONS.stderr.value.write("General syntax error at preprocessor (unexpected End of File?)")
        sys.exit(1)


def filter(input, filename = '<internal>'):
    ''' Filter the input string thought the preprocessor.
    result is appended to OUTPUT global str
    '''
    CURRENT_FILE.append(filename)
    LEXER.input(input, filename)
    parser.parse(lexer = LEXER, debug = OPTIONS.Debug.value > 2)
    CURRENT_FILE.pop()


def main(argv):
    global OUTPUT, ID_TABLE, ENABLED

    ENABLED = True
    ID_TABLE = zxbpplex.ID_TABLE = DefinesTable()

    if argv:
        CURRENT_FILE.append(argv[0])
    else:
        CURRENT_FILE.append('<stdout>')

    if OPTIONS.Sinclair.value:
        include_once(search_filename('sinclair.bas', 0), 0)
        parser.parse(lexer = LEXER, debug = OPTIONS.Debug.value > 2)

    OUTPUT += LEXER.include(CURRENT_FILE[-1])
    parser.parse(lexer = LEXER, debug = OPTIONS.Debug.value > 2)
    CURRENT_FILE.pop()


parser = yacc.yacc(method = 'LALR', tabmodule = 'zxbpptab')


# ------- ERROR And Warning messages ----------------


def msg(lineno, smsg):
    OPTIONS.stderr.value.write('%s:%i: %s\n' % (os.path.basename(CURRENT_FILE[-1]), lineno, smsg))


def error(lineno, str):
    msg(lineno, 'Error: %s' % str)
    sys.exit(1)


def warning(lineno, str):
    msg(lineno, 'Warning: %s' % str)


if __name__ == '__main__':
    main(sys.argv[1:])
    OPTIONS.stdout.value.write(OUTPUT)

    

