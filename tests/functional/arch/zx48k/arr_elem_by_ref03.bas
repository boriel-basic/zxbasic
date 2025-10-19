REM Test passing an local array element by param


SUB Incr(ByRef x As UByte)
  LET x = x + 1
END SUB

SUB ProxyFunc(ByRef x as UByte)
  Incr(x)
END SUB

SUB test
  DIM a(2) As UByte => {1, 2, 3}
  ProxyFunc(a(1))
  POKE 0, a(1)
END SUB

test
