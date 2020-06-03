
FUNCTION test(i as UInteger) as String
   DIM k as Uinteger
   DIM x(3) as String
   FOR k = 0 to 3
      x(k) = "HELLO WORLD "
   NEXT
   RETURN x(i)
END FUNCTION

test(2)

