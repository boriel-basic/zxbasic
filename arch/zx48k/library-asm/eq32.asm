__EQ32:	; Test if 32bit value HLDE equals top of the stack
		; Returns result in A: 0 = False, FF = True
		exx
		pop bc ; Return address
		exx

		xor a	; Reset carry flag
		pop bc
		sbc hl, bc ; Low part
		ex de, hl 
		pop bc
		sbc hl, bc ; High part

		exx
		push bc ; CALLEE
		exx

		ld a, h
		or l
		or d
		or e   ; a = 0 and Z flag set only if HLDE = 0
		ld a, 1
		ret z
		xor a
		ret
