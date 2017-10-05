REM Error x is an array, not an scalar

DIM v as Float = 1.5

RESTORE

DATA 10, 25 * v, SIN(v) * tan(v)^2, PI * v


DIM c, d as Float
FOR i = 1 TO 4:
READ c, d
PRINT c, d
NEXT i




