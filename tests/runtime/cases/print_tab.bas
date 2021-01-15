#include "lib/tst_framework.bas"

INIT("Testing TAB")

f$=CHR(22,6,27,16,2,17,5,19,1,71) 'PRINT AT 6,27;"G"   - fine, so other control codes are not counted
g$=CHR(22,7,10,17,0,23,31,0,32)   'PRINT AT 7,10; INK 0; TAB 31; " " last char is wrong. Should be a space
'PRINT AT 8,31;"-"                 'to measure the wrong positions
'PRINT a$;b$;c$;d$;e$;f$;g$
PRINT f$;g$;
'PRINT AT 10,28;"HI"               'fine at same coords
'PRINT AT 2,0;"--"                 'to measure the wrong positions

FINISH

