#include <memcopy.bas>
#include "lib/tst_framework.bas"

INIT("Testing memcopy to screen")

FOR i = 1 to 10
    PRINT "TEST ";
NEXT


memcopy(16384, 40000, 6912)
cls
pause 50
memcopy(40000, 16384, 6912)

PRINT AT 20,0;
REPORT_OK
