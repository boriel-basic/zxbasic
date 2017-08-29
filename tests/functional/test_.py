#!/usr/bin/env python
# vim:ts=4:et:ai

import sys
import six
import os
import doctest
import test


__doc__ = """
>>> process_file('doloop1.bas')
doloop1.bas:2: warning: Infinite empty loop
>>> process_file('dountil1.bas')
dountil1.bas:2: warning: Condition is always False
dountil1.bas:2: warning: Empty loop
>>> process_file('doloop2.bas')
doloop2.bas:4: warning: Using default implicit type 'ubyte' for 'a'
doloop2.bas:5: warning: Condition is always True
doloop2.bas:8: warning: Condition is always True
doloop2.bas:12: warning: Condition is always False
doloop2.bas:4: warning: Variable 'a' is never used
>>> process_file('dowhile1.bas')
dowhile1.bas:1: warning: Condition is always True
dowhile1.bas:1: warning: Empty loop
>>> process_file('subcall1.bas')
subcall1.bas:6: 'test' is SUBROUTINE not a FUNCTION
>>> process_file('subcall2.bas')
subcall2.bas:6: 'test' is a SUBROUTINE, not a FUNCTION
>>> process_file('prepro05.bi')
prepro05.bi:3: warning: "test" redefined (previous definition at prepro05.bi:2)
>>> process_file('prepro07.bi')
prepro07.bi:2: Error: Duplicated name parameter "x"
>>> process_file('prepro28.bi')
prepro28.bi:3: Error: invalid directive #defien
>>> process_file('param3.bas')
param3.bas:3: warning: Parameter 's' is never used
param3.bas:5: Function 'test' (previously declared at 3) type mismatch
param3.bas:6: Type Error: Function must return a numeric value, not a string
>>> process_file('typecast1.bas')
typecast1.bas:5: Cannot convert value to string. Use STR() function
>>> process_file('typecast2.bas')
typecast2.bas:1: warning: Parameter 'c' is never used
typecast2.bas:10: Cannot convert string to a value. Use VAL() function
>>> process_file('jr1.asm')
jr1.asm:12: Relative jump out of range
>>> process_file('jr2.asm')
jr2.asm:2: Relative jump out of range
>>> process_file('mcleod3.bas')
mcleod3.bas:3: 'GenerateSpaces' is neither an array nor a function.
mcleod3.bas:1: warning: Parameter 'path' is never used
mcleod3.bas:6: warning: Parameter 'n' is never used
>>> process_file('poke3.bas')
poke3.bas:4: Variable 'a' is an array and cannot be used in this context
>>> process_file('poke5.bas')
poke5.bas:4: Variable 'a' is an array and cannot be used in this context
>>> process_file('arrlabels10.bas')
arrlabels10.bas:3: warning: Using default implicit type 'float' for 'a'
arrlabels10.bas:3: Can't convert non-numeric value to float at compile time
arrlabels10.bas:3: Can't convert non-numeric value to float at compile time
>>> process_file('arrlabels10c.bas')
arrlabels10c.bas:3: Can't convert non-numeric value to string at compile time
arrlabels10c.bas:3: Can't convert non-numeric value to string at compile time
>>> process_file('arrlabels10d.bas')
arrlabels10d.bas:3: Undeclared array "a"
>>> process_file('arrlabels11.bas')
arrlabels11.bas:4: Initializer expression is not constant.
>>> process_file('lexerr.bas')
lexerr.bas:1: ignoring illegal character '%'
lexerr.bas:1: Syntax Error. Unexpected token '1.0' <NUMBER>
>>> process_file('opt2_nogoto.bas')
opt2_nogoto.bas:2: Undeclared label "nolabel"
>>> process_file('nosub.bas')
nosub.bas:3: function 'nofunc' declared but not implemented
"""


def process_file(fname):
    test.main(['-S', '-q', fname])


class OutputProxy(six.StringIO):
    """A simple interface to replace sys.stdout so
    doctest can capture it.
    """
    def write(self, str_):
        sys.stdout.write(str_)

    def flush(self):
        sys.stdout.flush()


def main():
    try:
        test.set_temp_dir()
        test.FOUT = OutputProxy()
        doctest.testmod()
    finally:
        os.rmdir(test.TEMP_DIR)


if __name__ == '__main__':
    main()
