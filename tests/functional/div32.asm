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
	ld a, (_a)
	ld de, (_a + 1)
	ld bc, (_a + 3)
	call __NEGF
	push bc
	push de
	ld h, a
	pop de
	ld (_a), hl
	ld (_a + 2), de
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
#line 1 "negf.asm"
	
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
	
#line 2 "negf.asm"
#line 1 "ftou32reg.asm"
	
	
	
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
	
#line 3 "negf.asm"
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
#line 4 "negf.asm"
	
	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)
	
	; All of them uses C EDHL registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order BC DE HL (B not used).
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------
	
__NEGF:	; A = -A 
		call __FPSTACK_PUSH
		
		; ------------- ROM NEGATE
		rst 28h
		defb 1Bh	; NEGF
		defb 38h;   ; END CALC
	
		jp __FPSTACK_POP
	
	
#line 28 "div32.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
