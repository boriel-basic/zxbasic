#include once <neg32.asm>
#include once <u32tofreg.asm>

__F16TOFREG:	; Converts a 16.16 signed fixed point (stored in DEHL)
				; to a Floating Point Number returned in (C ED CB)
    PROC

    LOCAL __F16TOFREG2

	ld a, d
	or a		; Test sign

	jp p, __F16TOFREG2	; It was positive, proceed as 32bit unsigned

	call __NEG32		; Convert it to positive
	call __F16TOFREG2	; Convert it to Floating point

	set 7, e			; Put the sign bit (negative) in the 31bit of mantissa
	ret


__F16TOFREG2:	; Converts an unsigned 32 bit integer (DEHL)
				; to a Floating point number returned in C DE HL

    ld a, d
    or e
    or h
    or l
    ld b, h
    ld c, l
    ret z       ; Return 00 0000 0000 if 0

	push de
	push hl

	exx
	pop de  ; Loads integer into B'C' D'E' 
	pop bc
	exx

	ld l, 112	; Exponent
	ld bc, 0	; DEBC = 0
	ld d, b
	ld e, c
	jp __U32TOFREG_LOOP ; Proceed as an integer

    ENDP

