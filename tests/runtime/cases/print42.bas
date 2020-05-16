' vim: ts=4:et:
' Test for print42 routine and memory leaks
' (compile with --debug-memory)

#include <alloc.bas>
#include <print42.bas>
#include "lib/tst_framework.bas"

INIT(PAPER 1; INK 7; "Test PRINT42")

DIM n,x,y as uInteger

RANDOMIZE 3769   ' Fixed (prime) seed to get replicable results

FOR n=1 to 10000
    y=1+rnd*22
    x=rnd*41
    printat42(y, x)
    print42("ABCDEFGHIJKLMNOPQRSTUVWXYZ"(n MOD 26 TO n MOD 26))
    print at 23,0;n;"  y:";y;"  x:";x;"  L:";n mod 26; "  "; memavail; "  ";
NEXT n
FINISH
