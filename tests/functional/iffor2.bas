
DIM a as Byte

IF a < 10 THEN FOR a = 1 TO 10
    IF a > 1 THEN
        FOR a = a + 1 TO 10
        NEXT
    END IF
   NEXT a

