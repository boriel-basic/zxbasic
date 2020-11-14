__PISTORE16: ; stores an integer in hl into address IX + BC; Destroys DE
		ex de, hl
		push ix
		pop hl
		add hl, bc

__ISTORE16:  ; Load address at hl, and stores E,D integer at that address
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a
		ld (hl), e
		inc hl
		ld (hl), d
		ret
		
