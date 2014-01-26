' vim: ts=4:et:
' Test for print64 routine and memory leaks
' (compile with --debug-memory)

#include <print64.bas>


DIM n,x,y as uInteger
CLS

FOR n=1 to 10000
    y=rnd*23
    x=rnd*63
    printat64(y, x)
    print64("ABCDEFGHIJKLMNOPQRSTUVWXYZ"(n MOD 26 TO n MOD 26))
    print at 23,0;n;"  y:";y;"  x:";x;"  L:";n mod 26; "    ";
NEXT n

pause 0
END


