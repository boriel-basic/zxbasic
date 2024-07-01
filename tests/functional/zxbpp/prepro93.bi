
REM Checks -D MACRO=VALUE is defined correctly from zxbc commandline

#ifdef MACRO
#  if MACRO != VALUE
#    error This should not happen
#  endif
#else
OK
#endif
