__PISTOREF:	; Indect Stores a float (A, E, D, C, B) at location stored in memory, pointed by (IX + HL)
		push de
		ex de, hl	; DE <- HL
		push ix
		pop hl		; HL <- IX
		add hl, de  ; HL <- IX + HL
		pop de

__ISTOREF:  ; Load address at hl, and stores A,E,D,C,B registers at that address. Modifies A' register
        ex af, af'
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a     ; HL = (HL)
        ex af, af'

__STOREF:	; Stores the given FP number in A EDCB at address HL
		ld (hl), a
		inc hl
		ld (hl), e
		inc hl
		ld (hl), d
		inc hl
		ld (hl), c
		inc hl
		ld (hl), b
		ret
		
