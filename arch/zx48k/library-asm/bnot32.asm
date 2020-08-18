; vim:ts=4:et:
; FASTCALL bitwise or 32 version.
; result in DE,HL
; __FASTCALL__ version (operands: A, H)
; Performs 32bit NEGATION (cpl)
; Input: DE,HL
; Output: DE,HL <- NOT DE,HL 

__BNOT32:
	ld a, l
	cpl
	ld l, a

	ld a, h
	cpl
	ld h, a

	ld a, e
	cpl
	ld e, a
	
	ld a, d
	cpl
	ld d, a

    ret 

