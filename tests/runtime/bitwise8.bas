
DIM a as uByte = 1

PRINT a band 0; " = 0"
PRINT a band 1; " = 1"
PRINT a + 3 band 2; " = 0"
PRINT a + 3 band 2; " = 2"
PRINT
PRINT a bor 3; " = 3"
PRINT a bor 0; " = "; a
PRINT a bor 2; " = 3"
PRINT
PRINT bnot a; " = 254"
PRINT bnot (a - 1); " = 255"
PRINT
PRINT 255 bxor a; " = 254"
PRINT a bxor a; " = 0"


