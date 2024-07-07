#include <input.bas>

10 PRINT "Enter a number from 0 to 9"
   PRINT "Only values 0, 1 and 2 will"
   PRINT "be dispatched"
   PRINT "> ";
   LET X$ = INPUT(1)
   IF X$ < "0" or X$ > "9" THEN GOTO 10
20 ON VAL(X) GOTO 50, 100, 150
30 PRINT "Invalid choice: "; X
40 GOTO 10
50 PRINT "You chose option 0"
60 END
100 PRINT "You chose option 1"
110 END
150 PRINT "You chose option 2"
160 END

