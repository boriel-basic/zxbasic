__ABS32:
	bit 7, d
	ret z

__NEG32: ; Negates DEHL (Two's complement)
	ld a, l
	cpl
	ld l, a

	ld a, h
	cpl
	ld h, a

	ld a, e
	cpl
	ld e, a
	
	ld a, d
	cpl
	ld d, a

	inc l
	ret nz

	inc h
	ret nz

	inc de
	ret

