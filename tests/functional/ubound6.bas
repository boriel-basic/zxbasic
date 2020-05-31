
DIM b, c as UInteger
SUB test
  DIM a(3 TO 5, 7 TO 9) As UByte
  FOR b = 0 TO 3
  c = UBound(a, b)
  NEXT
END SUB

test

