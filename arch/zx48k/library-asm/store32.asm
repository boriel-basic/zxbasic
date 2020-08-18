__PISTORE32:
		push hl
		push ix
		pop hl
		add hl, bc
		pop bc

__ISTORE32:  ; Load address at hl, and stores E,D,B,C integer at that address
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a

__STORE32:	; Stores the given integer in DEBC at address HL
		ld (hl), c
		inc hl
		ld (hl), b
		inc hl
		ld (hl), e
		inc hl
		ld (hl), d
		ret
		
