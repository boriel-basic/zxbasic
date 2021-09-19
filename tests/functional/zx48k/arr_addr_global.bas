REM test @arr(x, y) for GLOBAL scope
DIM aglobal(2, 2) as UByte => {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}
POKE @aglobal(1, 1), 99
