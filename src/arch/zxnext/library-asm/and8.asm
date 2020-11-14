; FASTCALL boolean and 8 version.
; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
; Performs 8bit and 8bit and returns the boolean

__AND8:
	or a
	ret z
	ld a, h
	ret 

