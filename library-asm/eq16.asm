__EQ16:	; Test if 16bit values HL == DE
		; Returns result in A: 0 = False, FF = True
		or a	; Reset carry flag
		sbc hl, de 

		ld a, h
		or l
		sub 1  ; sets carry flag only if a = 0
		sbc a, a
		
		ret

