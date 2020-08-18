; Loads DE into DE
; Modifies C register
; There is a routine similar to this one 
; at ROM address L2AEE
__LOAD_DE_DE:
	ex de, hl
	ld c, (hl)
	inc hl
	ld h, (hl)
	ld l, c
	ex de, hl
	ret

