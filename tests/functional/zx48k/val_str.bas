REM VAL of a constant string is folded and
REM computed in compile time. The compiler will
REM use Python eval to evaluate it.

DIM a as UByte = VAL("1 + 2")

