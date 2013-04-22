' vim: ts=4:et:
' Test for print42 routine and memory leaks
' (compile with --debug-memory)

#include <print42.bas>


DIM n,x,y as uInteger
CLS

FOR n=1 to 10000
    y=rnd*23
    x=rnd*41
    printat42(y, x)
    print42("ABCDEFGHIJKLMNOPQRSTUVWXYZ"(n MOD 26 TO n MOD 26))
    print at 23,0;n;"  y:";y;"  x:";x;"  L:";n mod 26; "    ";
NEXT n

pause 0
END


