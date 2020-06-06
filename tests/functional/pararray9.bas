
DIM q(10) as UInteger
FUNCTION test(q() as UInteger) as Byte
   q(3) = 7
END FUNCTION

test(q)

