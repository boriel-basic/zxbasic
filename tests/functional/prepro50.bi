#define X A(1)
#define A(x) x

#if X
print 1
' This should return this code once filtered by preprocessor
#endif



