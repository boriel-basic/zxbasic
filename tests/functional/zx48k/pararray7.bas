
FUNCTION test(a() as Byte, q() as UInteger) as Byte
   DIM i as Ubyte = 3
   q(i) = 7
   a(i, 1) = 8
END FUNCTION

DIM z(5, 4) as UByte
DIM q(10) as Integer
test(z, q)
