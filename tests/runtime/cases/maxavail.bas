#include "lib/tst_framework.bas"

INIT("Testing MEMAVAIL, MAXAVAIL")

#include <alloc.bas>
DIM hasError as Ubyte = 0

SUB showResult()
  PRINT TAB 12;
  IF hasError THEN
    hasError = 0
    SHOW_ERROR
  ELSE
    SHOW_OK
  END IF
  PRINT
END SUB


PRINT maxavail(); " "; memavail();
LET hasError = maxavail() <> 4764 or memavail() <> 4764
showResult()

a$ = "HELLO WORLD"
PRINT maxavail(); " "; memavail();
LET hasError = maxavail() <> 4749 or memavail() <> 4749
showResult()

a$ = a$ + a$
PRINT maxavail(); " "; memavail();
LET hasError = maxavail() <> 4723 or memavail() <> 4738
showResult()

FINISH
