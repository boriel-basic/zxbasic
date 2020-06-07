#include "lib/tst_framework.bas"

INIT("Testing global array(i, j, k)")

DIM a(7, 19, 11) as UInteger
DIM p as UInteger = @a(0, 0, 0)
DIM i as UInteger
DIM j as UInteger
DIM k as UInteger
DIM m as UInteger

FOR i = 0 TO 7
  FOR j = 0 TO 19
    FOR k = 0 TO 11

    LET m = i * j * k
    LET a(i, j, k) = m
    PRINT AT 2, 0; i; " "; j; " "; k; " "

    IF PEEK(UInteger, p) <> m THEN
      REPORT_FAIL
    END IF

    LET p = p + 2

    NEXT k
  NEXT j
NEXT i

REPORT_OK
