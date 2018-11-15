#pragma arrayCheck=true
#define __CHECK_ARRAY_BOUNDARY__

DIM a(10, 5) as byte
DIM c as Byte

DIM b as UInteger = 5
Let a(b, b) = 7
Let c = a(b + 6, b)
let c = c
