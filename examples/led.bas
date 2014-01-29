REM Include these libraries 
#include <point.bas>
 
  5 REM Display letters amplified
 10 LET scaleX = 2: LET scaleY = 3
 20 LET w$ = "ZX BASIC": REM What to print
 30 PAPER 7: INK 7: CLS
 40 PRINT AT 23,0; w$;:INK 0
 50 FOR x = 0 TO LEN(w$) * 8
 60 FOR y = 0 TO 7
 70 IF POINT(x, y) THEN 
 80 FOR i = 0 TO scaleX - 1
 90 FOR j = 0 TO scaleY - 1
100 PLOT x * scaleX + i, 84 + y * scaleY + j
110 NEXT j
120 NEXT i
130 END IF
140 NEXT y
150 NEXT x
