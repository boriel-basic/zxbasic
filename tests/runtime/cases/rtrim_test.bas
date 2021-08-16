#include "lib/tst_framework.bas"

INIT("Test RTRIM$()")

#include <string.bas>
#include <alloc.bas>

print memavail; chr$(13); maxavail

print "'"; rtrim("", "a"); "'"
print "'"; rtrim("hello world", ""); "'"
print "'"; rtrim("hello world", "ld"); "'"
print "'"; rtrim("hello worldld", "ld"); "'"
print "'"; rtrim("hehehe", "he"); "'"
print "'"; rtrim("hhh", "h"); "'"
print "'"; rtrim("ahehehe", "he"); "'"

print memavail; chr$(13); maxavail

FINISH

