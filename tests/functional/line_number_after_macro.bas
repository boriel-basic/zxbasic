
#define BORDE(x) \
	asm \
		ld a,x \
		out (254),a \
	end asm

DIM a

BORDE(5): a = 1
a+

