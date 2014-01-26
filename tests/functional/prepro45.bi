#define X(a) a

#if X(0)
print 1
' This should return no code once filtered by preprocessor
#endif



