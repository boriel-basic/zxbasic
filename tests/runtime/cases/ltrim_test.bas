#include "lib/tst_framework.bas"

INIT("Test LTRIM$()")

#include <string.bas>
#include <alloc.bas>

print memavail; chr$(13); maxavail

print "'"; ltrim("", "a"); "'"
print "'"; ltrim("hello world", ""); "'"
print "'"; ltrim("hello world", "he"); "'"
print "'"; ltrim("hehello world", "he"); "'"
print "'"; ltrim("hehehe", "he"); "'"

print memavail; chr$(13); maxavail

FINISH

