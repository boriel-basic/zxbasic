	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	ld hl, (_a)
	ld de, (_a + 2)
	call __F16TOFREG
	ld hl, _b
	call __STOREF
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
#line 1 "f16tofreg.asm"

#line 1 "neg32.asm"

__ABS32:
		bit 7, d
		ret z

__NEG32: ; Negates DEHL (Two's complement)
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

		inc l
		ret nz

		inc h
		ret nz

		inc de
		ret

#line 2 "f16tofreg.asm"
#line 1 "u32tofreg.asm"


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

#line 3 "f16tofreg.asm"

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

#line 23 "castF16toF.bas"
#line 1 "storef.asm"

__PISTOREF:	; Indect Stores a float (A, E, D, C, B) at location stored in memory, pointed by (IX + HL)
			push de
			ex de, hl	; DE <- HL
			push ix
			pop hl		; HL <- IX
			add hl, de  ; HL <- IX + HL
			pop de

__ISTOREF:  ; Load address at hl, and stores A,E,D,C,B registers at that address. Modifies A' register
	        ex af, af'
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a     ; HL = (HL)
	        ex af, af'

__STOREF:	; Stores the given FP number in A EDCB at address HL
			ld (hl), a
			inc hl
			ld (hl), e
			inc hl
			ld (hl), d
			inc hl
			ld (hl), c
			inc hl
			ld (hl), b
			ret

#line 24 "castF16toF.bas"

ZXBASIC_USER_DATA:
_a:
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_b:
	DEFB 00, 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
