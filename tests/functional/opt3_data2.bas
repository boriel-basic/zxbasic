DIM a(9) AS UBYTE
 
FOR i = 0 TO 9: REM 0 TO 9 => 10 elements
    READ a(i)
    PRINT a(i)
NEXT i
 
REM notice the a * a expression
DATA 2, 4, 6 * i, 7, 0
DATA a(0), a(1), a(2), a(3), a(4)

