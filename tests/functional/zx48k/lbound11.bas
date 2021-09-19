
DIM b, c as UInteger

DECLARE SUB test1(a1() as UByte)

SUB test2(a2() as UByte)
    test1(a2)
END SUB

SUB test1(a1() as UByte)
  FOR b = 0 TO 3
      c = LBound(a1, b)
  NEXT
END SUB

SUB test3()
    DIM a(3 TO 5, 7 TO 9) As UByte
    test2(a)
END SUB

test3()
