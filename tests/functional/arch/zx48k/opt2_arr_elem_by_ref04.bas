SUB plusOne(ByRef a As Ubyte)
  LET a = a + 1
END SUB

DIM i as UInteger = 3
DIM myArray(5) as Ubyte

plusOne(myArray(i))
POKE 0, myArray(i)


