
FUNCTION test(a as Byte, q() as UInteger) as Byte
   DIM i as Ubyte = 3
   q(i) = 7
END FUNCTION

DIM q(10) as Integer
test(2, q)

