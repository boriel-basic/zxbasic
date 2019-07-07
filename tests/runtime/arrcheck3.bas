
DIM a(23, 31) as Uinteger
DIM p as UInteger = @a(0, 0)
DIM i as Uinteger
DIM j as UInteger
DIM m as UInteger
CLS

FOR i = 0 TO 23
 FOR j = 0 TO 10
 LET m = i * 32 + j
 PRINT i; ","; j; " "; m; " "; @a(i, j); " "; p
 LET p = p + 2
 NEXT j
 STOP
NEXT i

PRINT INK 4; FLASH 1; " OK "

