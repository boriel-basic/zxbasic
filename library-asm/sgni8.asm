; Returns SGN (SIGN) for 8 bits signed integer

__SGNI8:
	or a
	ret z
	ld a, 1
	ret p
	neg
	ret

