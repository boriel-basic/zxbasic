
DIM b, c as UInteger

DIM a(3 TO 5, 7 TO 9) As UByte
SUB test(a() as UByte)
  FOR b = 0 TO 3
      c = LBound(a, b)
  NEXT
END SUB

test(a)
c = LBound(a, b)  ' This will signal LBound is used on Array a


