
INK 7: PAPER 2
CLS
FOR i = 0 to 15:
	for j = 0 to 15:
		print at i+1, j+1; PAPER (i * 16 + j) MOD 2; (i * 16 + j) MOD 2;
	next
next

#include <scroll.bas>

FOR i = 0 TO 30:
	for j = 1 to 8:
		scrollRight()
	next
	for j = 1 to 8:
		scrollLeft()
	next
NEXT


