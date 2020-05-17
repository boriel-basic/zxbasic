REM test @arr(x, y) for LOCAL scope
SUB test
    DIM alocal(2, 2) as UByte => {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}
    POKE @alocal(1, 1), 99
END SUB
test

