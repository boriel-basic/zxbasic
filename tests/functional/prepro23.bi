' Must return
' PRINT 10;

#define macro(x, y, z) x(y, z)
#define func1(x, y) x(y)
#define func2(x) PRINT x;

macro(func1, func2, 10)



