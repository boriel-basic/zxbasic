#include "lib/tst_framework.bas"
INIT("Testing (str) == (str) [STREQ]")

DIM A, B As String

LET A = "X"
LET B = A( TO LEN(A) - 2)

IF NOT (B = "") THEN
   REPORT_FAIL
END IF

IF NOT ("" = B) THEN
   REPORT_FAIL
END IF

REPORT_OK
