#include once <neg32.asm>

__FTOU32REG:	; Converts a Float to (un)signed 32 bit integer (NOTE: It's ALWAYS 32 bit signed)
				; Input FP number in A EDCB (A exponent, EDCB mantissa)
				; Output: DEHL 32 bit number (signed)
	PROC

	LOCAL __IS_FLOAT

	or a
	jr nz, __IS_FLOAT 
	; Here if it is a ZX ROM Integer

	ld h, c
	ld l, d
	ld a, e	 ; Takes sign: FF = -, 0 = +
	ld de, 0
	inc a
	jp z, __NEG32	; Negates if negative
	ret

__IS_FLOAT:  ; Jumps here if it is a true floating point number
	ld h, e	
	push hl  ; Stores it for later (Contains Sign in H)

	push de
	push bc

	exx
	pop de   ; Loads mantissa into C'B' E'D' 
	pop bc	 ; 

	set 7, c ; Highest mantissa bit is always 1
	exx

	ld hl, 0 ; DEHL = 0
	ld d, h
	ld e, l

	;ld a, c  ; Get exponent
	sub 128  ; Exponent -= 128
	jr z, __FTOU32REG_END	; If it was <= 128, we are done (Integers must be > 128)
	jr c, __FTOU32REG_END	; It was decimal (0.xxx). We are done (return 0)

	ld b, a  ; Loop counter = exponent - 128

__FTOU32REG_LOOP:
	exx 	 ; Shift C'B' E'D' << 1, output bit stays in Carry
	sla d
	rl e
	rl b
	rl c

    exx		 ; Shift DEHL << 1, inserting the carry on the right
	rl l
	rl h
	rl e
	rl d

	djnz __FTOU32REG_LOOP

__FTOU32REG_END:
	pop af   ; Take the sign bit
	or a	 ; Sets SGN bit to 1 if negative
	jp m, __NEG32 ; Negates DEHL
	
	ret

	ENDP


__FTOU8:	; Converts float in C ED LH to Unsigned byte in A
	call __FTOU32REG
	ld a, l
	ret

