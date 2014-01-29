__EQ32:	; Test if 32bit value HLDE equals top of the stack
		; Returns result in A: 0 = False, FF = True
		exx
		pop bc ; Return address
		exx

		or a	; Reset carry flag
		pop bc
		sbc hl, bc ; Low part
		ex de, hl 
		pop bc
		sbc hl, bc ; Hight part

		exx
		push bc ; CALLEE
		exx

		ld a, h
		or l
		or d
		or e   ; a = 0 only if HLDE = 0
		sub 1  ; sets carry flag only if a = 0
		sbc a, a
		
		ret

