
DIM b, c as UInteger

DECLARE SUB test2(a2() as String)

SUB test3(a3() as String)
  FOR b = 0 TO 3
      c = LBound(a3, b)
  NEXT
END SUB

SUB test1()
    DIM a1(3 TO 5, 7 TO 9) As String
    test2(a1)
END SUB

SUB test2(a2() as String)
    test3(a2)
END SUB

test1()

