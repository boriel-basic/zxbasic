
DIM i as UInteger = 0
FUNCTION test() as String
   DIM x(3) as String
   x(i) = "HELLO WORLD"
   RETURN x(i)
END FUNCTION

test
