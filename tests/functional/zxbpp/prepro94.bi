

#ifdef MACRO
#  ifndef ANOTHER_MACRO
#    error This should not happen
#  endif
#else
  OK
#endif
