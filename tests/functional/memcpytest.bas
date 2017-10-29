
CLS
FOR i = 1 to 10
    PRINT "TEST ";
NEXT

#include <memcopy.bas>

memcopy(16384, 40000, 6912)
cls
pause 0
memcopy(40000, 16384, 6912)
 
