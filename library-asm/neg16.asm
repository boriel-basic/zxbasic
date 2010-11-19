; Negates HL value (16 bit)
__ABS16:
	bit 7, h
	ret z

__NEGHL:
	ld a, l			; HL = -HL
	cpl
	ld l, a
	ld a, h
	cpl
	ld h, a
	inc hl
	ret

