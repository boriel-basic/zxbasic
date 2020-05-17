REM test @arr(x, y) for GLOBAL scope

#include "lib/tst_framework.bas"
INIT("Testing @ARRAY(a, b, c...)")

DIM aglobal(2, 2) as UByte => {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}
PRINT aglobal(1, 1); " -> ";
POKE @aglobal(1, 1), 99
PRINT aglobal(1, 1); " ";
SHOW_RESULTLN(aglobal(1, 1) = 99)


SUB test1
    REM test @arr(x, y) for LOCAL scope
    DIM alocal(2, 2) as UByte => {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}
    PRINT alocal(1, 1); " -> ";
    POKE @alocal(1, 1), 99
    PRINT alocal(1, 1); " ";
    SHOW_RESULTLN(alocal(1, 1) = 99)
END SUB
test1


DIM aglobal1(2, 2) as UByte => {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}
SUB test2(alocal() as UByte)
    REM test @arr(x, y) for PARAM scope
    PRINT alocal(1, 1); " -> ";
    POKE @alocal(1, 1), 99
    PRINT alocal(1, 1); " ";
    SHOW_RESULTLN(alocal(1, 1) = 99)

END SUB
test2(aglobal1)

FINISH
