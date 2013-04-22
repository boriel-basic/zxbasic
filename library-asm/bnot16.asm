; vim:ts=4:et:
; FASTCALL bitwise or 16 version.
; result in HL
; __FASTCALL__ version (operands: A, H)
; Performs 16bit NEGATION
; Input: HL
; Output: HL <- NOT HL 

__BNOT16:
	ld a, h
    cpl
    ld h, a

    ld a, l
    cpl
    ld l, a

    ret 

