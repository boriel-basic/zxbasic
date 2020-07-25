#include <winscroll.bas>

INK 7: PAPER 2
CLS
FOR i = 0 to 15:
    PRINT PAPER 4; AT i + 1, 0; "#"; AT i + 1, 17; "#";
    for j = 0 to 15:
        PRINT PAPER 4; AT 0, j + 1; "#"; AT 17, j + 1; "#";
        print at i+1, j+1; PAPER (i * 16 + j) MOD 2; (i * 16 + j) MOD 10;
    next
next

pause 100

for j = 1 to 5
    winScrollDown(0, 1, 7, 5)
    pause 10
next

for j = 1 to 5
    winScrollUp(13, 1, 7, 5)
    pause 10
next

for j = 1 to 9
    winScrollRight(5, 10, 8, 4)
    pause 10
next

for j = 1 to 9
    winScrollLeft(10, 10, 8, 4)
    pause 10
next

