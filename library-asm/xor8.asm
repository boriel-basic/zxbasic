; vim:ts=4:et:
; FASTCALL boolean xor 8 version.
; result in Accumulator (0 False, not 0 True)
; __FASTCALL__ version (operands: A, H)
; Performs 8bit xor 8bit and returns the boolean

__XOR16:
	ld a, h
	or l
    ld h, a

	ld a, d
	or e

__XOR8:
    sub 1
    sbc a, a
    ld l, a  ; l = 00h or FFh

    ld a, h
    sub 1
    sbc a, a ; a = 00h or FFh
    xor l
    ret 

