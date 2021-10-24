#include "lib/tst_framework.bas"

INIT("Testing SCREEN X,Y coords shift")

#define SCREEN_Y_OFFSET 96
#define SCREEN_X_OFFSET 127

#include <point.bas>

PLOT 0, 0
PLOT -20, 20
PRINT POINT(0, 0); " "; POINT(-20, 20); " "; POINT(20, -20); " "; POINT(-20, -20)

FINISH
