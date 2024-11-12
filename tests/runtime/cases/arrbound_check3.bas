#pragma array_check = yes
#include "lib/tst_framework.bas"

INIT("Testing global array\#013boundary check #3")

DIM a(2 TO 23, 1 TO 31) as Uinteger

FOR i = 2 TO 23
 FOR j = 0 TO 31 : REM j = 0 => Out of Boundary
 PRINT AT 5, 0; i; " "; j;
 LET m = i * 32 + j
 LET a(i, j) = m
 IF a(i, j) <> m THEN
   REPORT_FAIL
 END IF
 NEXT j
NEXT i

REPORT_FAIL : REM should never reach this line
