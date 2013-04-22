#define X A(0)
#define A(x) x

#if X(A)
print 1
' This should return no code once filtered by preprocessor
#endif



