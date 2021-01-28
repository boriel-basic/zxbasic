#include "lib/tst_framework.bas"

a$ = "-20"

INIT("Test INT (negative number)")

PRINT INT(VAL(a$))

if INT(VAL(a$)) = -20 then
  SHOW_OK: PRINT
else SHOW_ERROR: PRINT
END IF

FINISH

