; vim:ts=4:et:
; FASTCALL bitwise xor 16 version.
; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
; Performs 16bit xor 16bit and returns the boolean
; Input: HL, DE
; Output: HL <- HL XOR DE

__BXOR16:
	ld a, h
	xor d
    ld h, a

    ld a, l
    xor e
    ld l, a

    ret 

