#include <point.bas>

10 CLS:CIRCLE 127,87,40: REM A small figure or it will overflow
20 LET x=127:LET y=87
30 GOSUB 100: STOP

100 PLOT x, y
110 IF NOT POINT(x+1, y) THEN 
	LET x=x+1
	GOSUB 100
	LET x=x-1
    END IF

120 IF NOT POINT(x-1, y) THEN 
	LET x=x-1
	GOSUB 100
	LET x=x+1
    END IF

130 IF NOT POINT(x, y+1) THEN 
	LET y=y+1
	GOSUB 100
	LET y=y-1
    END IF

140 IF NOT POINT(x, y-1) THEN 
	LET y=y-1
	GOSUB 100
	LET y=y+1
    END IF

500 RETURN
