#include "lib/tst_framework.bas"

DIM i AS Byte = -128
DIM j AS Byte
DIM ii, jj AS Integer
DIM Counter as ULong = 0

INIT("Testing (byte) < (byte) [LTi8]")

DO
    j = -128
    ii = i

    DO
        jj = j
        If (i < j) XOR (ii < jj) THEN
            PRINT i; "<"; j; " = "; (i < j); " ";
            REPORT_FAIL
        End If

        Counter = Counter + 1
        j = j + 1
    LOOP UNTIL j = -128

    i = i + 1
LOOP UNTIL i = -128

IF Counter <> 65536 THEN
    PRINT "Iterations: "; Counter; " ";
    REPORT_FAIL
ELSE
    REPORT_OK
END IF

