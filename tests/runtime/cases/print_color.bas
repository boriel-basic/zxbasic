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
 PRINT Txt;
End sub
