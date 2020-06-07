REM fixes heapsize to 4K. Needed for make this test deterministic
#pragma heap_size = 4096

#include <alloc.bas>

#include "lib/tst_framework.bas"

INIT("Testing heap size")


PRINT memavail(); " == "; maxavail(); " ";
IF memavail() <> maxavail() THEN
   REPORT_FAIL
ELSE
   REPORT_OK
END IF


