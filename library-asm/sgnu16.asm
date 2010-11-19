; Returns SGN (SIGN) for 16 bits unsigned integer

__SGNU16:
	ld a, h
	or l
	ret z
	ld a, 1
	ret

