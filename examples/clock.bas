REM From the ZX Spectrum MANUAL
REM A Clock program

REM First we draw the Sphere
CLS
FOR n = 1 to 12
    PRINT AT 10 - (10 * COS(n * PI / 6) - 0.5), 16 + (0.5 + 10 * SIN(n * PI / 6)); n
NEXT n
PRINT AT 23, 0; "PRESS ANY KEY TO EXIT";

FUNCTION t AS ULONG
	RETURN INT((65536 * PEEK (23674) + 256 * PEEK(23673) + PEEK (23672))/50)
END FUNCTION

DIM t1 as FLOAT

OVER 1
WHILE INKEY$ = ""
	LET t1 = t()
	LET a = t1 / 30 * PI: REM a is the seconds pointer in radians
	LET sx = 72 * SIN a : LET sy = 72 * COS a
	PLOT 131, 107: DRAW sx, sy

	LET t2 = t()
	WHILE (t2 <= t1) AND (INKEY$ = "")
		REM WARNING: Empty loops might be optimized and removed
		let t2 = t()
	END WHILE : REM Wait until the moment to move it

	PLOT 131, 107: DRAW sx, sy
END WHILE

