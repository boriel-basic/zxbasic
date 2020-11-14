; vim:ts=4:et:
; FASTCALL bitwise and16 version.
; result in hl 
; __FASTCALL__ version (operands: A, H)
; Performs 16bit or 16bit and returns the boolean
; Input: HL, DE
; Output: HL <- HL AND DE

__BAND16:
	ld a, h
	and d
    ld h, a

    ld a, l
    and e
    ld l, a

    ret 

