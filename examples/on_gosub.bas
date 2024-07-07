#include <input.bas>

10 PRINT "Enter a number from 0 to 9"
   PRINT "Only values 0, 1 and 2 will"
   PRINT "be dispatched"
   PRINT "> ";
   LET X$ = INPUT(1)
   IF X$ < "0" or X$ > "9" THEN GOTO 10
20 LET ok = 0
   ON VAL(X) GOSUB 50, 100, 150: IF ok THEN END
   GOTO 10
30 PRINT "Invalid choice: "; X
40 RETURN
50 PRINT "You chose option 0": LET ok = 1
60 RETURN
100 PRINT "You chose option 1": LET ok = 1
110 RETURN
150 PRINT "You chose option 2": LET ok = 1
160 RETURN

