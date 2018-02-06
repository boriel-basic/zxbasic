
#include <basic.bas>

' Some Sinclair BASIC tokens ASCII codes
#define FOR_ 235
#define TO_ 204
#define BORDER_ 231
#define PAUSE_ 242
#define NEXT_ 243

REM Executes "FOR i = 0 TO 7: BORDER i: PAUSE 40: NEXT i" twice
FOR i = 1 TO 2
EvalBasic(CHR$(FOR_, CODE "i", CODE "=", 48, TO_, 55, CODE ":", _
               BORDER_, CODE "i", CODE ":", PAUSE_, 52, 48, CODE ":", _
               NEXT_, CODE "i", 13))
NEXT

