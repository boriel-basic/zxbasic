
REM Checks -D MACRO=VALUE is defined correctly from zxbc commandline

#ifdef MACRO
#  error This should not happen
#else
OK
#endif

