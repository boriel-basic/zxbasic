
FUNCTION test(i as UInteger) as UInteger
   DIM k as UInteger
   DIM x(3) as UInteger
   FOR k = 0 to 3
      x(k) = 2 * k
   NEXT
   RETURN x(i)
END FUNCTION

test(2)
