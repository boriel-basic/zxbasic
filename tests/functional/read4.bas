REM Error x is an array, not an scalar

DIM v as Float = 1

RESTORE

DATA 10, 25 * v, SIN(v) * tan(v)^2, "Hello"


DIM x(4) as Float
LET x(2) = v * 3
READ x(2)



