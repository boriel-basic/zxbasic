; vim:ts=4:et:
; FASTCALL bitwise or 16 version.
; result in HL
; __FASTCALL__ version (operands: A, H)
; Performs 16bit or 16bit and returns the boolean
; Input: HL, DE
; Output: HL <- HL OR DE

__BOR16:
	ld a, h
	or d
    ld h, a

    ld a, l
    or e
    ld l, a

    ret 

