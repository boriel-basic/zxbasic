#include "lib/tst_framework.bas"

INIT("Testing SCREEN X,Y coords shift")

#define SCREEN_Y_OFFSET 96
#define SCREEN_X_OFFSET 127

PLOT 0, 0
DRAW 10, 10

PLOT -20, 20
DRAW 20, 20, 10

CIRCLE 0, 0, 45

FINISH
