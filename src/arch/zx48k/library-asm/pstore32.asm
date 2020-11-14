#include once <store32.asm>

; Stores a 32 bit integer number (DE,HL) at (IX + BC)
__PSTORE32:
		push hl
		push ix
		pop hl
		add hl, bc
		pop bc
		jp __STORE32
