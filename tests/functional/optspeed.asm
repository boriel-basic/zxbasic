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
__LABEL__finish:
	call _choque
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
_choque:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	push hl
	push hl
	call _choque
	dec a
	jp nz, __LABEL0
	ld a, (_face)
	or a
	jp nz, __LABEL3
	xor a
	ld hl, (_ds1 - 1)
	sub h
	ccf
	jp nc, __LABEL4
	ld a, 1
	ld (_face), a
	ld (ix-1), 3
	jp __LABEL5
__LABEL4:
	ld a, 3
	ld (_face), a
	ld (ix-1), 4
__LABEL5:
__LABEL3:
	jp __LABEL1
__LABEL0:
	call _choque
	sub 8
	jp nz, __LABEL6
	ld a, (_face)
	sub 3
	jp nz, __LABEL9
	push ix
	pop hl
	ld de, -6
	add hl, de
	call __PLOADF
	push bc
	push de
	push af
	ld a, 000h
	ld de, 00000h
	ld bc, 00000h
	call __LEF
	or a
	jp z, __LABEL10
	ld a, 2
	ld (_face), a
	ld (ix-1), 4
	jp __LABEL11
__LABEL10:
	xor a
	ld (_face), a
	ld (ix-1), 3
__LABEL11:
__LABEL9:
	jp __LABEL7
__LABEL6:
	call _choque
	sub 3
	jp nz, __LABEL12
	ld a, (_face)
	or a
	jp nz, __LABEL14
	ld a, 3
	ld (_face), a
	ld (ix-1), 4
	jp __LABEL15
__LABEL14:
	ld a, (_face)
	dec a
	jp nz, __LABEL17
	ld a, 2
	ld (_face), a
	ld (ix-1), 3
__LABEL17:
__LABEL15:
	jp __LABEL13
__LABEL12:
	call _choque
	sub 6
	jp nz, __LABEL18
	ld a, (_face)
	dec a
	jp nz, __LABEL20
	xor a
	ld (_face), a
	ld (ix-1), 4
	jp __LABEL21
__LABEL20:
	ld a, (_face)
	sub 2
	jp nz, __LABEL23
	ld a, 3
	ld (_face), a
	ld (ix-1), 3
__LABEL23:
__LABEL21:
	jp __LABEL19
__LABEL18:
	call _choque
	sub 12
	jp nz, __LABEL24
	ld a, (_face)
	sub 2
	jp nz, __LABEL26
	ld a, 1
	ld (_face), a
	ld (ix-1), 4
	jp __LABEL27
__LABEL26:
	ld a, (_face)
	sub 3
	jp nz, __LABEL29
	xor a
	ld (_face), a
	ld (ix-1), 3
__LABEL29:
__LABEL27:
	jp __LABEL25
__LABEL24:
	call _choque
	sub 9
	jp nz, __LABEL30
	ld a, (_face)
	or a
	jp nz, __LABEL32
	ld a, 1
	ld (_face), a
	ld (ix-1), 3
	jp __LABEL33
__LABEL32:
	ld a, (_face)
	sub 3
	jp nz, __LABEL35
	ld a, 2
	ld (_face), a
	ld (ix-1), 4
__LABEL35:
__LABEL33:
	jp __LABEL31
__LABEL30:
	call _choque
	sub 7
	jp nz, __LABEL36
	ld a, (_face)
	sub 3
	jp z, __LABEL__finish
__LABEL39:
	ld a, (_face)
	sub 2
	jp nz, __LABEL40
	ld (ix-1), 3
	jp __LABEL41
__LABEL40:
	ld (ix-1), 4
__LABEL41:
	ld a, 3
	ld (_face), a
	jp __LABEL37
__LABEL36:
	call _choque
	sub 14
	jp nz, __LABEL42
	ld a, (_face)
	or a
	jp z, __LABEL__finish
__LABEL45:
	ld a, (_face)
	sub 3
	jp nz, __LABEL46
	ld (ix-1), 3
	jp __LABEL47
__LABEL46:
	ld (ix-1), 4
__LABEL47:
	xor a
	ld (_face), a
	jp __LABEL43
__LABEL42:
	call _choque
	sub 13
	jp nz, __LABEL48
	ld a, (_face)
	dec a
	jp z, __LABEL__finish
__LABEL51:
	ld a, (_face)
	sub 2
	jp nz, __LABEL52
	ld (ix-1), 3
	jp __LABEL53
__LABEL52:
	ld (ix-1), 4
__LABEL53:
	ld a, 1
	ld (_face), a
	jp __LABEL49
__LABEL48:
	call _choque
	sub 11
	jp nz, __LABEL54
	ld a, (_face)
	sub 2
	jp z, __LABEL__finish
__LABEL57:
	ld a, (_face)
	sub 3
	jp nz, __LABEL58
	ld (ix-1), 4
	jp __LABEL59
__LABEL58:
	ld (ix-1), 3
__LABEL59:
	ld a, 2
	ld (_face), a
	jp __LABEL55
__LABEL54:
	call _choque
	sub 5
	jp nz, __LABEL60
	ld a, (_face)
	or a
	jp nz, __LABEL62
	xor a
	ld hl, (_ds1 - 1)
	sub h
	ccf
	jp nc, __LABEL64
	ld a, 1
	ld (_face), a
	ld (ix-1), 3
	jp __LABEL65
__LABEL64:
	ld a, 3
	ld (_face), a
	ld (ix-1), 4
__LABEL65:
	jp __LABEL63
__LABEL62:
	ld a, (_face)
	sub 2
	jp nz, __LABEL67
	xor a
	ld hl, (_ds1 - 1)
	sub h
	ccf
	jp nc, __LABEL68
	ld a, 1
	ld (_face), a
	ld (ix-1), 4
	jp __LABEL69
__LABEL68:
	ld a, 3
	ld (_face), a
	ld (ix-1), 3
__LABEL69:
__LABEL67:
__LABEL63:
	jp __LABEL61
__LABEL60:
	call _choque
	sub 10
	jp nz, __LABEL71
	ld a, (_face)
	dec a
	jp nz, __LABEL72
	push ix
	pop hl
	ld de, -6
	add hl, de
	call __PLOADF
	push bc
	push de
	push af
	ld a, 000h
	ld de, 00000h
	ld bc, 00000h
	call __LEF
	or a
	jp z, __LABEL74
	ld a, 2
	ld (_face), a
	ld (ix-1), 3
	jp __LABEL75
__LABEL74:
	xor a
	ld (_face), a
	ld (ix-1), 4
__LABEL75:
	jp __LABEL73
__LABEL72:
	ld a, (_face)
	sub 3
	jp nz, __LABEL77
	push ix
	pop hl
	ld de, -6
	add hl, de
	call __PLOADF
	push bc
	push de
	push af
	ld a, 000h
	ld de, 00000h
	ld bc, 00000h
	call __LEF
	or a
	jp z, __LABEL78
	ld a, 2
	ld (_face), a
	ld (ix-1), 4
	jp __LABEL79
__LABEL78:
	xor a
	ld (_face), a
	ld (ix-1), 3
__LABEL79:
__LABEL77:
__LABEL73:
__LABEL71:
__LABEL61:
__LABEL55:
__LABEL49:
__LABEL43:
__LABEL37:
__LABEL31:
__LABEL25:
__LABEL19:
__LABEL13:
__LABEL7:
__LABEL1:
_choque__leave:
	ld sp, ix
	pop ix
	ret
#line 1 "lef.asm"

#line 1 "u32tofreg.asm"

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

#line 2 "u32tofreg.asm"
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

#line 2 "lef.asm"
#line 1 "ftou32reg.asm"



__FTOU32REG:	; Converts a Float to (un)signed 32 bit integer (NOTE: It's ALWAYS 32 bit signed)
					; Input FP number in A EDCB (A exponent, EDCB mantissa)
				; Output: DEHL 32 bit number (signed)
		PROC

		LOCAL __IS_FLOAT
		LOCAL __NEGATE

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
		jp m, __NEGATE ; Negates DEHL

		ret

__NEGATE:
	    exx
	    ld a, d
	    or e
	    or b
	    or c
	    exx
	    jr z, __END
	    inc l
	    jr nz, __END
	    inc h
	    jr nz, __END
	    inc de
	LOCAL __END
__END:
	    jp __NEG32
		ENDP


__FTOU8:	; Converts float in C ED LH to Unsigned byte in A
		call __FTOU32REG
		ld a, l
		ret

#line 3 "lef.asm"
#line 1 "stackf.asm"

	; -------------------------------------------------------------
	; Functions to manage FP-Stack of the ZX Spectrum ROM CALC
	; -------------------------------------------------------------


	__FPSTACK_PUSH EQU 2AB6h	; Stores an FP number into the ROM FP stack (A, ED CB)
	__FPSTACK_POP  EQU 2BF1h	; Pops an FP number out of the ROM FP stack (A, ED CB)

__FPSTACK_PUSH2: ; Pushes Current A ED CB registers and top of the stack on (SP + 4)
	                 ; Second argument to push into the stack calculator is popped out of the stack
	                 ; Since the caller routine also receives the parameters into the top of the stack
	                 ; four bytes must be removed from SP before pop them out

	    call __FPSTACK_PUSH ; Pushes A ED CB into the FP-STACK
	    exx
	    pop hl       ; Caller-Caller return addr
	    exx
	    pop hl       ; Caller return addr

	    pop af
	    pop de
	    pop bc

	    push hl      ; Caller return addr
	    exx
	    push hl      ; Caller-Caller return addr
	    exx

	    jp __FPSTACK_PUSH


__FPSTACK_I16:	; Pushes 16 bits integer in HL into the FP ROM STACK
					; This format is specified in the ZX 48K Manual
					; You can push a 16 bit signed integer as
					; 0 SS LL HH 0, being SS the sign and LL HH the low
					; and High byte respectively
		ld a, h
		rla			; sign to Carry
		sbc	a, a	; 0 if positive, FF if negative
		ld e, a
		ld d, l
		ld c, h
		xor a
		ld b, a
		jp __FPSTACK_PUSH
#line 4 "lef.asm"

	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)

	; All of them uses A EDCB registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order A DE BC.
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------

__LEF:	; A <= B
		call __FPSTACK_PUSH2 ; B, A

		; ------------- ROM NO-L-EQL
		ld b, 0Ah	; B => A
		rst 28h
		defb 0Ah	; B => A
		defb 38h;   ; END CALC

		call __FPSTACK_POP
		jp __FTOU8 ; Convert to 8 bits

#line 361 "optspeed.bas"
#line 1 "ploadf.asm"

	; Parameter / Local var load
	; A => Offset
	; IX = Stack Frame
; RESULT: HL => IX + DE

#line 1 "iloadf.asm"

	; __FASTCALL__ routine which
	; loads a 40 bits floating point into A ED CB
	; stored at position pointed by POINTER HL
	;A DE, BC <-- ((HL))

__ILOADF:
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a

	; __FASTCALL__ routine which
	; loads a 40 bits floating point into A ED CB
	; stored at position pointed by POINTER HL
	;A DE, BC <-- (HL)

__LOADF:    ; Loads a 40 bits FP number from address pointed by HL
		ld a, (hl)
		inc hl
		ld e, (hl)
		inc hl
		ld d, (hl)
		inc hl
		ld c, (hl)
		inc hl
		ld b, (hl)
		ret

#line 7 "ploadf.asm"

__PLOADF:
	    push ix
	    pop hl
	    add hl, de
	    jp __LOADF

#line 362 "optspeed.bas"

ZXBASIC_USER_DATA:
_face:
	DEFB 00
_modoi:
	DEFB 00
_ds1:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
