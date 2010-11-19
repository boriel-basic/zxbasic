REM Sample circle drawing

DIM i, r, x, y, q as Float
DIM ax, ay, zx, zy, dx, dy as Ubyte

x = 127
y = 87
r = 40
q = 1 / r

FOR i = 0 TO PI/2 STEP q
	dy = SIN(i) * r
	dx = COS(i) * r

	zx = x - dx
	zy = y - dy
	ax = x + dx
	ay = y + dy

	PLOT ax, ay
	PLOT zx, ay
	PLOT ax, zy 
	PLOT zx, zy

NEXT i

