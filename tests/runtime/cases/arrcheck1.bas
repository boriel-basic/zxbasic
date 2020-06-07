
#include "lib/tst_framework.bas"

INIT("Testing global array(i, j)")

DIM a(23, 31) as Uinteger
DIM p as UInteger = @a(0, 0)
DIM i as Uinteger
DIM j as UInteger
DIM m as UInteger

FOR i = 0 TO 23
 FOR j = 0 TO 31
 LET m = i * 32 + j
 LET a(i, j) = m
 PRINT AT 2, 0; i; " "; j; " "; " "
 IF PEEK(UInteger, p) <> m THEN
    PRINT "Expected "; m; ", got "; PEEK(Uinteger, p); ", read: "; a(i, j)
    REPORT_FAIL
 END IF
 LET p = p + 2
 NEXT j
NEXT i

REPORT_OK
