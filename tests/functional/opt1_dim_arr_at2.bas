
DIM a(4, 4) as UByte at 20000
DIM c as UByte
LET c = a(2, 3)
LET c = @a(2, 3)

SUB test
  DIM a(4, 4) as Ubyte at 30000
  DIM c as UByte
  LET c = a(2, 3)
  LET c = @a(2, 3)
END SUB
test()
