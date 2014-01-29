; FASTCALL boolean and 32 version.
; Performs 32bit and 32bit and returns the boolean
; result in Accumulator (0 False, not 0 True)
; First operand in DE,HL 2nd operand into the stack

__AND32:
	ld a, l
	or h
	or e
	or d
	sub 1	
	sbc a

	ld c, a

	pop hl

	pop de
	ld a, d
	or e
	pop de
	or d
	or e
	sub 1
	sbc a

	or c
	cpl
	jp (hl)


