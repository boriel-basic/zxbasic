
INK 7: PAPER 2
CLS
FOR i = 0 to 15:
	for j = 0 to 15:
		print at i+1, j+1; PAPER (i * 16 + j) MOD 2; (i * 16 + j) MOD 2;
	next
next

#include <scroll.bas>

FOR i = 0 TO 30:
	for j = 1 to 16:
		scrollRight(40, 40, 100, 100)
	next
    for j = 1 to 16
		scrollDown(40, 40, 100, 100)
    next
    for j = 1 to 16
		scrollLeft(40, 40, 100, 100)
    next
    for j = 1 to 16
		scrollUp(40, 40, 100, 100)
    next
NEXT


