
DIM a(23, 31) as Uinteger
DIM p as UInteger = @a(0, 0)
DIM i as Uinteger
DIM j as UInteger
DIM m as UInteger
CLS

FOR i = 0 TO 23
 FOR j = 0 TO 31
 LET m = i * 32 + j
 LET a(i, j) = m
 PRINT AT 0, 0; i; " "; j; " "; " "
 IF PEEK(UInteger, p) <> m THEN
    PRINT INK 2; FLASH 1; " ERROR "
    PRINT "Expected "; m; ", got "; PEEK(Uinteger, p); ", read: "; a(i, j)
    STOP
 END IF
 LET p = p + 2
 NEXT j
NEXT i

PRINT INK 4; FLASH 1; " OK "

