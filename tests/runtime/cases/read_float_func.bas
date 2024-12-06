#include "lib/tst_framework.bas"

DIM v as Float = 1.5

RESTORE

DATA 10, 25 * v, SIN(v) * tan(v)^2, PI * v

INIT("Test reading FP from\#013function body")

function p()
    DIM c as Float
    FOR i = 0 TO 3:
    READ c
    PRINT c
    NEXT i
end function
p()

REPORT_OK
