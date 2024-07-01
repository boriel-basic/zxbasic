
#ifdef MACRO
#  define ANOTHER

#  ifdef ANOTHER
#    error This should never happen
#  else
#    error This should never happen
#  endif
#else
 OK
#endif
