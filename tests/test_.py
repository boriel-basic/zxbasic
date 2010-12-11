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
doloop2.bas:9: warning: Condition is always False
True
>>> test.testBAS('dowhile1.bas')
dowhile1.bas:1: warning: Condition is always True
True
>>> test.testBAS('subcall1.bas')
subcall1.bas:6: 'test' is SUB not a FUNCTION
True
>>> test.testBAS('subcall2.bas')
subcall2.bas:6: 'test' is a SUB, not a FUNCTION
True
'''

import test

if __name__ == '__main__':
    import doctest
    doctest.testmod()



