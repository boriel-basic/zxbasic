#pragma array_check = yes
#include "lib/tst_framework.bas"

INIT("Testing global array\#013boundary check")

DIM a(23, 31) as Uinteger

FOR i = 0 TO 23
 FOR j = 0 TO 31
 LET m = i * 32 + j
 LET a(i, j) = m
 NEXT j
NEXT i

REPORT_OK
