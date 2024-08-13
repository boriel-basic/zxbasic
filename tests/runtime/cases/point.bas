' PARAMS: -D SCREEN_X_OFFSET=127 -D SCREEN_Y_OFFSET=96
#include "lib/tst_framework.bas"

INIT("Testing SCREEN X,Y coords shift")

#include <point.bas>

PLOT 0, 0
PLOT -20, 20
PRINT POINT(0, 0); " "; POINT(-20, 20); " "; POINT(20, -20); " "; POINT(-20, -20)

FINISH
