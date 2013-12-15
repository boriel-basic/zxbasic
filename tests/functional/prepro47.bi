#define X(a) a
#define A 0

#if X(A)
print 1
' This should return no code once filtered by preprocessor
#endif



