DIM a as UByte
FUNCTION test(a as UByte) as UByte
  IF a < 10 THEN
     RETURN a
  END IF
  RETURN a
END FUNCTION

LET a = test(0)

