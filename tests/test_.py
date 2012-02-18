#!/usr/bin/env python
# vim:ts=4:et:ai

'''
>>> test.testBAS('doloop1.bas')
doloop1.bas:2: warning: Infinite empty loop
True
>>> test.testBAS('dountil1.bas')
dountil1.bas:2: warning: Condition is always False
dountil1.bas:2: warning: Empty loop
True
>>> test.testBAS("doloop2.bas")
doloop2.bas:5: warning: Condition is always True
doloop2.bas:8: warning: Condition is always True
doloop2.bas:12: warning: Condition is always False
True
>>> test.testBAS('dowhile1.bas')
dowhile1.bas:1: warning: Condition is always True
dowhile1.bas:1: warning: Empty loop
True
>>> test.testBAS('subcall1.bas')
subcall1.bas:6: 'test' is SUB not a FUNCTION
True
>>> test.testBAS('subcall2.bas')
subcall2.bas:6: 'test' is a SUB, not a FUNCTION
True
>>> test.testPREPRO('prepro05.bi')
prepro05.bi:3: Warning: "test" redefined (previous definition at prepro05.bi:2)
True
>>> test.testPREPRO('prepro07.bi')
prepro07.bi:2: Error: Duplicated name parameter "x"
True
>>> test.testPREPRO('prepro28.bi')
prepro28.bi:3: Error: invalid directive #defien
True
>>> test.testBAS('param3.bas')
param3.bas:5: Function 'test' (previusly declared at 3) type mismatch
param3.bas:6: Type Error: Function must return a numeric value, not a string
True
>>> test.testBAS('typecast1.bas')
typecast1.bas:5: Cannot convert value to string. Use STR() function
True
'''


import test

if __name__ == '__main__':
    import doctest
    doctest.testmod()



