#include "lib/tst_framework.bas"

DIM v as Fixed = 1.5

RESTORE

INIT("Test read FP into Fixed")



DATA 10, 25 * v, SIN(v) * tan(v)^2, PI * v

DIM i as UByte
DIM c(3) as Fixed

FOR i = 0 TO 3:
  READ c(i)
  PRINT c(i)
NEXT i

REPORT_OK
