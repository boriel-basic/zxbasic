__EQ16:	; Test if 16bit values HL == DE
		; Returns result in A: 0 = False, FF = True
		xor a	; Reset carry flag
		sbc hl, de
		ret nz
		inc a
		ret

