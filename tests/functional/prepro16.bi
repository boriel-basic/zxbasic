' Must return:
' PRINT 20;
' PRINT 10 + 20;


#define macro(x) PRINT x;
#define y 20

macro(y)
macro(10 + y)


