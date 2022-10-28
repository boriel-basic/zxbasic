#include "lib/tst_framework.bas"
INIT("Testing CHR$(22, y, x)")

DIM aS$(21)
DIM otro$
DIM x,y,i as ubyte  : REM aux

REM preparation sprite vars
RESTORE: FOR i=1 TO 21: REM bulls
READ zS$,x,y
LET aS$(i)=CHR$ (22)+CHR$ (y)+CHR$ (x)+zS$
LET otro$=CHR$(22)+CHR$(y)+CHR$(x)+zS$
PRINT AT 23,0;x;" ";y;" ";zS$;"     ";AT 0,0;
PRINT aS$(i);otro$;
NEXT i

REM bulls
DATA "AB",30,3,"CD",30,4,"EFG",25,3,"HIJ",25,4
DATA "KLM",21,3,"NOP",21,4,"QRS",15,3,"TUV",15,4
DATA "WXY",10,3,"Zab",10,4,"cd\#008",10,7,"ef\#008",10,8
DATA "ghi",14,7,"jkl",14,8,"mno",19,7,"pqr",19,8
DATA "stu",24,7,"vwx",24,8,"yz!",29,7,"""#$",29,8
DATA "A\#008\#008",31,11,"C\#008\#008",31,12,"EFG",26,11,"HIJ",26,12
DATA "KLM",20,11,"NOP",20,12,"QRS",14,11,"TUV",14,12
DATA "XY\#008",10,11,"ab\#008",10,12,"cd\#008",10,14,"cd\#008",10,14
DATA "ghi",13,14,"ghi",13,14,"mno",17,14,"r\#008\#008",19,15
DATA "stu",25,14,"v\#008\#008",25,15,"yz\#008",30,14,"yz\#008",30,14
DATA "   ",10,1,"   ",10,1

FINISH
