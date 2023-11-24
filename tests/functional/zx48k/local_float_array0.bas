REM Test reading a float from a local array

FUNCTION test() as Float
   DIM x(3) as Float = {0.0, 1.5, 2.5, 3.5}
   DIM i as UInteger = 1
   RETURN x(i)
END FUNCTION

DIM f As Float
LET f = test
