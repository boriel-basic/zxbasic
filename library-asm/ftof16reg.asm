#include once <ftou32reg.asm>

__FTOF16REG:	; Converts a Float to 16.16 (32 bit) fixed point decimal
				; Input FP number in A EDCB (A exponent, EDCB mantissa)

    ld l, a     ; Saves exponent for later
	or d
	or e
	or b
	or c
    ld h, e
	ret z		; Return if ZERO
	
	push hl  ; Stores it for later (Contains sign in H, exponent in L)

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
  
    pop bc

	ld a, c  ; Get exponent
	sub 112  ; Exponent -= 128 + 16

    push bc  ; Saves sign in b again

	jp z, __FTOU32REG_END	; If it was <= 128, we are done (Integers must be > 128)
	jp c, __FTOU32REG_END	; It was decimal (0.xxx). We are done (return 0)

	ld b, a  ; Loop counter = exponent - 128 + 16 (we need to shift 16 bit more)
	jp __FTOU32REG_LOOP ; proceed as an u32 integer

