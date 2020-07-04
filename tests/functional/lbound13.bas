
FUNCTION maxValue(a() as UByte) as UByte
  DIM result as UByte = 0
  DIM i as Uinteger
  FOR i = LBOUND(a, 1) TO UBOUND(a, 1)
    IF result < a(i) THEN result = a(i)
  NEXT i
  RETURN result
END FUNCTION

DIM x(4) As UByte => {1, 2, 3, 4, 5}
LET y = maxValue(x)

