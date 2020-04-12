
FUNCTION test(q() as UInteger) as Byte
   q(3) = 7
END FUNCTION

DIM q(10) as UInteger
test(q)

