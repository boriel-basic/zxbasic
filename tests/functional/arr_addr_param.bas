REM test @arr(x, y) for PARAM scope
DIM aglobal1(2, 2) as UByte => {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}

SUB test(alocal() as UByte)
    POKE @alocal(1, 1), 99
END SUB
test(aglobal1)

