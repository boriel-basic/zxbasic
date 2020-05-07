#include "lib/tst_framework.bas"

DIM i AS uByte = 0
DIM j AS uByte
DIM ii, jj AS uInteger
DIM Counter as ULong = 0

INIT("Testing (ubyte) >= (ubyte) [GEu8]")

DO
    j = 0
    ii = i

    DO
        jj = j
        If (i >= j) XOR (ii >= jj) THEN
            PRINT i; ">="; j; " = "; (i < j); " ";
            REPORT_FAIL
        End If

        Counter = Counter + 1
        j = j + 1
    LOOP UNTIL j = 0

    i = i + 1
LOOP UNTIL i = 0

IF Counter <> 65536 THEN
    PRINT "Iterations: "; Counter; " ";
    REPORT_FAIL
ELSE
    REPORT_OK
END IF

