
FUNCTION test(q() as UInteger) as Byte
   DIM i as Ubyte = 3
   q(i) = 7
END FUNCTION

DIM q(10) as UByte
test(q)
