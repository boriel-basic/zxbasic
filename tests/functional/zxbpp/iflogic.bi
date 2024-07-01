
#define A 1
#define B 2

#if A == 1 || B == 1
PRINT "Or works"
#endif

#if A == 1 && B == 2
PRINT "And works"
#endif

#if (A == 1 && B == 1) || B == 2
PRINT "Parenthesis works"
#endif

#if A == 1 && B != 2
PRINT "this should not happen!"
#endif
