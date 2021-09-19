
DIM b, c as UInteger

SUB test1(a1() as UByte)
  FOR b = 0 TO 3
      c = LBound(a1, b)
  NEXT
END SUB

SUB test3()
    DIM a(3 TO 5, 7 TO 9) As UByte
    test1(a)
END SUB

test3()
