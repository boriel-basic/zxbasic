' Must return 
' PRINT 10 ; PRINT 10

#define macro(x, y) x(y, 2) ; x(y)
#define test(arg) PRINT arg

macro(test, 10)

