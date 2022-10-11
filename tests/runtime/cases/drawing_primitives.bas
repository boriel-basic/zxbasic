#include "lib/tst_framework.bas"

INIT("Testing PRINT color")

Declare sub CenterText (ByVal Row as ubyte, ByVal Text as string)

Ink 6
Paper 1
Print "x";

Ink 7
Paper 0
Text ("Hello")
FINISH

Sub Text (ByVal Txt as string)
 PLOT 10, 10
 DRAW 20, 20
 CIRCLE 100, 100, 20
 DRAW 30, 30, 30
End sub
