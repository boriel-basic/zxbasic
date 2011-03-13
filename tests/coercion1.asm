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
	call __FTOU32REG
	ld a, l
	call BORDER
	ld a, (_b)
	ld de, (_b + 1)
	ld bc, (_b + 3)
	call __FTOU32REG
	ld a, l
	call BORDER
	ld hl, (_a + 3)
	push hl
	ld hl, (_a + 1)
	push hl
	ld a, (_a)
	push af
	ld a, 083h
	ld de, 00020h
	ld bc, 00000h
	call __MULF
	push bc
	push de
	push af
	ld a, 083h
	ld de, 000A0h
	ld bc, 00000h
	call __DIVF
	ld hl, 00000h
	push hl
	ld hl, 00000h
	push hl
	ld h, 082h
	push hl
	call __ADDF
	call __FTOU32REG
	ld a, l
	call BORDER
	ld a, (_c)
	call BORDER
	ld a, (_c)
	ld h, 3
	call __MUL8_FAST
	call BORDER
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
#line 1 "addf.asm"
#line 1 "stackf.asm"
	; -------------------------------------------------------------
	; Functions to manage FP-Stack of the ZX Spectrum ROM CALC
	; -------------------------------------------------------------
	
	
	__FPSTACK_PUSH EQU 2AB6h	; Stores an FP number into the ROM FP stack (A, ED CB)
	__FPSTACK_POP  EQU 2BF1h	; Pops an FP number out of the ROM FP stack (A, ED CB)
	
__FPSTACK_PUSH2: ; Pushes Current A ED CB registers and top of the stack on (SP + 4)
	                 ; Second argument to push into the stack calculator is popped out of the stack
	                 ; Since the caller routine also receives the parameters into the top of the stack
	                 ; For bytes must be removed from SP before pop them out
	
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
#line 2 "addf.asm"
	
	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)
	; All of them uses A EDCB registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order AF DE BC (F not used).
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------
	
__ADDF:	; Addition
		call __FPSTACK_PUSH2
		
		; ------------- ROM ADD
		rst 28h
		defb 0fh	; ADD
		defb 38h;   ; END CALC
	
		jp __FPSTACK_POP
	
#line 63 "coercion1.bas"
#line 1 "mulf.asm"
	
	
	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)
	; All of them uses A EDCB registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order A DE BC.
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------
	
__MULF:	; Multiplication
		call __FPSTACK_PUSH2
		
		; ------------- ROM MUL
		rst 28h
		defb 04h	; 
		defb 38h;   ; END CALC
	
		jp __FPSTACK_POP
	
#line 64 "coercion1.bas"
#line 1 "mul8.asm"
__MUL8:		; Performs 8bit x 8bit multiplication
		PROC
	
		;LOCAL __MUL8A
		LOCAL __MUL8LOOP
		LOCAL __MUL8B
				; 1st operand (byte) in A, 2nd operand into the stack (AF)
		pop hl	; return address
		ex (sp), hl ; CALLE convention
	
;;__MUL8_FAST: ; __FASTCALL__ entry
	;;	ld e, a
	;;	ld d, 0
	;;	ld l, d
	;;	
	;;	sla h	
	;;	jr nc, __MUL8A
	;;	ld l, e
	;;
;;__MUL8A:
	;;
	;;	ld b, 7
;;__MUL8LOOP:
	;;	add hl, hl
	;;	jr nc, __MUL8B
	;;
	;;	add hl, de
	;;
;;__MUL8B:
	;;	djnz __MUL8LOOP
	;;
	;;	ld a, l ; result = A and HL  (Truncate to lower 8 bits)
	
__MUL8_FAST: ; __FASTCALL__ entry, a = a * h (8 bit mul) and Carry
	
	    ld b, 8
	    ld l, a
	    xor a
	
__MUL8LOOP:
	    add a, a ; a *= 2
	    sla l
	    jp nc, __MUL8B
	    add a, h
	
__MUL8B:
	    djnz __MUL8LOOP
		
		ret		; result = HL
		ENDP
	
#line 65 "coercion1.bas"
#line 1 "divf.asm"
	
#line 1 "error.asm"
	; Simple error control routines
; vim:ts=4:et:
	
	ERR_NR    EQU    23610    ; Error code system variable
	
	
	; Error code definitions (as in ZX spectrum manual)
	
; Set error code with:
	;    ld a, ERROR_CODE
	;    ld (ERR_NR), a
	
	
	ERROR_Ok                EQU    -1
	ERROR_SubscriptWrong    EQU     2
	ERROR_OutOfMemory       EQU     3
	ERROR_OutOfScreen       EQU     4
	ERROR_NumberTooBig      EQU     5
	ERROR_InvalidArg        EQU     9
	ERROR_IntOutOfRange     EQU    10
	ERROR_InvalidColour     EQU    19
	ERROR_BreakIntoProgram  EQU    20
	ERROR_TapeLoadingErr    EQU    26
	
	
	; Raises error using RST #8
__ERROR:
	    ld (__ERROR_CODE), a
	    rst 8
__ERROR_CODE:
	    nop
	    ret
	
	; Sets the error system variable, but keeps running.
	; Usually this instruction if followed by the END intermediate instruction.
__STOP:
	    ld (ERR_NR), a
	    ret
#line 3 "divf.asm"
	
	; -------------------------------------------------------------
	; Floating point library using the FP ROM Calculator (ZX 48K)
	
	; All of them uses C EDHL registers as 1st paramter.
	; For binary operators, the 2n operator must be pushed into the
	; stack, in the order BC DE HL (B not used).
	;
	; Uses CALLEE convention
	; -------------------------------------------------------------
	
__DIVF:	; Division
		PROC
		LOCAL __DIVBYZERO
		LOCAL TMP, ERR_SP
	
	TMP         EQU 23629 ;(DEST)
	ERR_SP      EQU 23613
	
		call __FPSTACK_PUSH2
	
		ld hl, (ERR_SP)
		ld (TMP), hl
		ld hl, __DIVBYZERO
		push hl
		ld hl, 0
		add hl, sp
		ld (ERR_SP), hl
		
		; ------------- ROM DIV
		rst 28h
		defb 01h	; EXCHANGE
		defb 05h	; DIV
		defb 38h;   ; END CALC
	
		pop hl
		ld hl, (TMP)
		ld (ERR_SP), hl
	
		jp __FPSTACK_POP
	
__DIVBYZERO:
		ld hl, (TMP)
		ld (ERR_SP), hl
	
		ld a, ERROR_NumberTooBig
		ld (ERR_NR), a
	
		; Returns 0 on DIV BY ZERO error
		xor a
		ld b, a
		ld c, a
		ld d, a
		ld e, a
		ret
	
		ENDP
	
#line 66 "coercion1.bas"
#line 1 "border.asm"
	; __FASTCALL__ Routine to change de border
	; Parameter (color) specified in A register
	
	BORDER EQU 229Bh
	
	; Nothing to do! (Directly from the ZX Spectrum ROM)
	
#line 67 "coercion1.bas"
#line 1 "ftou32reg.asm"
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
	
#line 2 "ftou32reg.asm"
	
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
	
#line 68 "coercion1.bas"
	
ZXBASIC_USER_DATA:
_a:
	DEFB 00, 00, 00, 00, 00
_c:
	DEFB 00
_b:
	DEFB 00, 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
