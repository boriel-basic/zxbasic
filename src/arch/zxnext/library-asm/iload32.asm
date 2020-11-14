; __FASTCALL__ routine which
; loads a 32 bits integer into DE,HL
; stored at position pointed by POINTER HL
; DE,HL <-- (HL)

__ILOAD32:
	ld e, (hl)	
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	ex de, hl
	ret

