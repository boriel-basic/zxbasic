' vim: ts=4:et:
' Test for print64 routine and memory leaks
' (compile with --debug-memory)

#include <alloc.bas>
#include <print64.bas>
#include "lib/tst_framework.bas"

INIT(PAPER 1; INK 7; "Test PRINT64")

DIM n,x,y as uInteger

FOR n=1 to 10000
    y=1+rnd*22
    x=rnd*63
    printat64(y, x)
    print64("ABCDEFGHIJKLMNOPQRSTUVWXYZ"(n MOD 26 TO n MOD 26))
    print at 23,0;n;"  y:";y;"  x:";x;"  L:";n mod 26; "  "; memavail; "  ";
NEXT n
FINISH
