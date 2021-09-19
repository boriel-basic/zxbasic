
DIM b, c as UInteger
DIM a(3 TO 5, 7 TO 9) As UByte

DECLARE SUB test1(a() as UByte)

SUB test2(b() as UByte)
    test1(b)
END SUB

SUB test1(a() as UByte)
  FOR b = 0 TO 3
      c = UBound(a, b)
  NEXT
END SUB



test2(a)
