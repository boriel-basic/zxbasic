
SUB test
  DIM a(2) as UByte
  let b = 1
  POKE 0, UBOUND(a, b)
  POKE 1, LBOUND(a, b)
END SUB

test
