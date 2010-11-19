#!/usr/bin/env python
# vim:ts=4:et:ai

'''
>>> test.testBAS('doloop1.bas')
doloop1.bas:2: warning: Infinite empty loop
True
>>> test.testBAS('dountil1.bas')
dountil1.bas:2: warning: Condition is always False
True
>>> test.testBAS('dowhile1.bas')
dowhile1.bas:1: warning: Condition is always True
True
'''

import test

if __name__ == '__main__':
    import doctest
    doctest.testmod()



