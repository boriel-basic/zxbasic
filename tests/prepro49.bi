#define X A(0)
#define A(x) x

#if X
print 1
' This should return no code once filtered by preprocessor
#endif



