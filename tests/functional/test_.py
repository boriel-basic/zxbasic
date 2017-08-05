#!/usr/bin/env python
# vim:ts=4:et:ai

import sys
import test

__doc__ = """
>>> test.main(['-q', 'doloop1.bas'])
doloop1.bas:2: warning: Infinite empty loop
>>> test.main(['-q', 'dountil1.bas'])
dountil1.bas:2: warning: Condition is always False
dountil1.bas:2: warning: Empty loop
>>> test.main(['-q', 'doloop2.bas'])
doloop2.bas:4: warning: Using default implicit type 'ubyte' for 'a'
doloop2.bas:5: warning: Condition is always True
doloop2.bas:8: warning: Condition is always True
doloop2.bas:12: warning: Condition is always False
doloop2.bas:4: warning: Variable 'a' is never used
>>> test.main(['-q', 'dowhile1.bas'])
dowhile1.bas:1: warning: Condition is always True
dowhile1.bas:1: warning: Empty loop
>>> test.main(['-q', 'subcall1.bas'])
subcall1.bas:6: 'test' is SUBROUTINE not a FUNCTION
>>> test.main(['-q', 'subcall2.bas'])
subcall2.bas:6: 'test' is a SUBROUTINE, not a FUNCTION
>>> test.main(['-q', 'prepro05.bi'])
prepro05.bi:3: warning: "test" redefined (previous definition at prepro05.bi:2)
>>> test.main(['-q', 'prepro07.bi'])
prepro07.bi:2: Error: Duplicated name parameter "x"
>>> test.main(['-q', 'prepro28.bi'])
prepro28.bi:3: Error: invalid directive #defien
>>> test.main(['-q', 'param3.bas'])
param3.bas:3: warning: Parameter 's' is never used
param3.bas:5: Function 'test' (previously declared at 3) type mismatch
param3.bas:6: Type Error: Function must return a numeric value, not a string
>>> test.main(['-q', 'typecast1.bas'])
typecast1.bas:5: Cannot convert value to string. Use STR() function
>>> test.main(['-q', 'typecast2.bas'])
typecast2.bas:1: warning: Parameter 'c' is never used
typecast2.bas:10: Cannot convert string to a value. Use VAL() function
>>> test.main(['-q', 'jr1.asm'])
jr1.asm:12: Error: Relative jump out of range
>>> test.main(['-q', 'jr2.asm'])
jr2.asm:2: Error: Relative jump out of range
>>> test.main(['-q', 'mcleod3.bas'])
mcleod3.bas:3: 'GenerateSpaces' is neither an array nor a function.
mcleod3.bas:1: warning: Parameter 'path' is never used
mcleod3.bas:6: warning: Parameter 'n' is never used
>>> test.main(['-q', 'poke3.bas'])
poke3.bas:4: Variable 'a' is an array and cannot be used in this context
>>> test.main(['-q', 'poke5.bas'])
poke5.bas:4: Variable 'a' is an array and cannot be used in this context
"""


class OutputProxy(object):
    """A simple interface to replace sys.stdout so
    doctest can capture it.
    """
    def write(self, str_):
        sys.stdout.write(str_)

    def flush(self):
        sys.stdout.flush()


def main():
    import doctest
    test.FOUT = OutputProxy()
    doctest.testmod()


if __name__ == '__main__':
    main()
