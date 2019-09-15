#Circle.Bas

```
Program: circle.bas
```

```
REM Sample circle drawing without using the CIRCLE command

DIM i, r, x, y, q as FLOAT
DIM ax, ay, zx, zy, dx, dy as Integer

x = 127
y = 87
r = 40
q = 1 / r

FOR i = 0 TO PI / 2 STEP q
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
```
