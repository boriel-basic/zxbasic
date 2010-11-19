#include once <neg32.asm>
__I8TOFREG:
	ld l, a
	rlca
	sbc a, a	; A = SGN(A)
	ld h, a
	ld e, a
	ld d, a

__I32TOFREG:	; Converts a 32bit signed integer (stored in DEHL)
				; to a Floating Point Number returned in (A ED CB)

	ld a, d
	or a		; Test sign

	jp p, __U32TOFREG	; It was positive, proceed as 32bit unsigned

	call __NEG32		; Convert it to positive
	call __U32TOFREG	; Convert it to Floating point

	set 7, e			; Put the sign bit (negative) in the 31bit of mantissa
	ret

__U8TOFREG:
				; Converts an unsigned 8 bit (A) to Floating point
	ld l, a
	ld h, 0
	ld e, h
	ld d, h

__U32TOFREG:	; Converts an unsigned 32 bit integer (DEHL)
				; to a Floating point number returned in A ED CB

    PROC

    LOCAL __U32TOFREG_END

	ld a, d
	or e
	or h
	or l
    ld b, d
	ld c, e		; Returns 00 0000 0000 if ZERO
	ret z

	push de
	push hl

	exx
	pop de  ; Loads integer into B'C' D'E' 
	pop bc
	exx

	ld l, 128	; Exponent
	ld bc, 0	; DEBC = 0
	ld d, b
	ld e, c

__U32TOFREG_LOOP: ; Also an entry point for __F16TOFREG
	exx
	ld a, d 	; B'C'D'E' == 0 ?
	or e
	or b
	or c
	jp z, __U32TOFREG_END	; We are done

	srl b ; Shift B'C' D'E' >> 1, output bit stays in Carry
	rr c
	rr d
	rr e
	exx

	rr e ; Shift EDCB >> 1, inserting the carry on the left
	rr d
	rr c
	rr b

	inc l	; Increment exponent
	jp __U32TOFREG_LOOP


__U32TOFREG_END:
	exx
    ld a, l     ; Puts the exponent in a
	res 7, e	; Sets the sign bit to 0 (positive)

	ret
    ENDP

