REM Error x is an array, not an scalar

DIM v as Float = 1.5

RESTORE

DATA 10, 25 * v, SIN(v) * tan(v)^2, PI * v

DIM i as UByte


DIM c(3) as Float
FOR i = 0 TO 3:
READ c(i)
PRINT c(i)
NEXT i




