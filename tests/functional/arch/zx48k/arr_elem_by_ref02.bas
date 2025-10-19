REM Test passing an local array element by ref


SUB Incr(ByRef x As UByte)
  LET x = x + 1
END SUB

SUB test
  DIM a(2) As UByte => {1, 2, 3}
  Incr(a(1))
  POKE 0, a(1)
END SUB

test
