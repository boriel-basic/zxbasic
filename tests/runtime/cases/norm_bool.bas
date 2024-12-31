#include "lib/tst_framework.bas"

INIT("Test BOOL Normalization")

DIM a as UByte

PRINT "PRINT: "; a = a
PRINT "SHL: "; (a = a) SHL 1; " "; 1 SHL (a = a); " "; (a = a) SHL (a = a)
PRINT "SHR: "; (a = a) SHR 1; " "; 1 SHR (a = a); " "; (a = a) SHR (a = a)
PRINT "ADD: "; (a = a) + (a = a)
PRINT "SUB: "; (a = a) - (a = a)
PRINT "MUL: "; (a = a) * (a = a)
PRINT "DIV: "; (a = a) / (a = a)
PRINT "LET: ";: LET a = (a = a): PRINT a
PRINT "OR: "; (a = a) OR (a = a)
PRINT "AND: "; (a = a) AND (a = a)
PRINT "XOR: "; (a = a) XOR (a = a)


FINISH

