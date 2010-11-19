; Returns SGN (SIGN) for 32 bits unsigned integer

__SGNU32:
	ld a, h
	or l
	or d
	or e
	ret z

	ld a, 1
	ret

