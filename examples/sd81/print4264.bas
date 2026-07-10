#include <print42.bas>
#include <print64.bas>

CLS
PRINT AT 0, 0; "print42/print64 test"

printat42(3, 0)
print42("HELLO 42 COLUMNS TEST 0123456789")

printat64(10, 0)
print64("HELLO 64 COLUMNS TEST 0123456789")

PAUSE 0
