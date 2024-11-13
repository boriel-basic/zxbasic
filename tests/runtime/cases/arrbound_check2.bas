#pragma array_check = yes
#include "lib/tst_framework.bas"

INIT("Testing global array\#013boundary check #2")

DIM a(23, 31) as Uinteger

FOR i = 0 TO 23
 FOR j = 0 TO 32 : REM j = 32 => Out of Boundary
 LET m = i * 32 + j
 LET a(i, j) = m
 IF a(i, j) <> m THEN
   REPORT_FAIL
 END IF
 NEXT j
NEXT i

REPORT_FAIL: REM Should never reach this line
