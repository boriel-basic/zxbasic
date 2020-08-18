; FASTCALL boolean and 16 version.
; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: DE, HL)
; Performs 16bit and 16bit and returns the boolean

__AND16:
	ld a, h
	or l
	ret z

	ld a, d
	or e
	ret 

