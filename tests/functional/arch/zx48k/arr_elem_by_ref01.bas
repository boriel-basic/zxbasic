REM Test passing an array element by ref

DIM a(2) As UByte => {1, 2, 3}

SUB Incr(ByRef x As UByte)
  LET x = x + 1
END SUB

Incr(a(1))
POKE 0, a(1)
