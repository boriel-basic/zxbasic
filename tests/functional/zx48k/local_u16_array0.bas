
FUNCTION test() as UInteger
   DIM y(3) as UInteger => {11, 22, 33, 44}
   y(3) = 77
   return y(3)
END FUNCTION

test
