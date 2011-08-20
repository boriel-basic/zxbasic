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
	ld hl, (_level)
	ld de, (_level + 2)
	push de
	push hl
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	pop hl
	pop de
	call __DIVI32
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __SWAP32
	call __DIVI32
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __SWAP32
	call __DIVI32
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __SWAP32
	call __DIVI32
	ld (_l), hl
	ld (_l + 2), de
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
#line 1 "div32.asm"
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
	
#line 2 "div32.asm"
	
				 ; ---------------------------------------------------------
__DIVU32:    ; 32 bit unsigned division
	             ; DEHL = Dividend, Stack Top = Divisor
	             ; OPERANDS P = Dividend, Q = Divisor => OPERATION => P / Q
				 ;
				 ; Changes A, BC DE HL B'C' D'E' H'L'
				 ; ---------------------------------------------------------
	        exx
	        pop hl   ; return address
	        pop de   ; low part
	        ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
	
__DIVU32START: ; Performs D'E'H'L' / HLDE
	        ; Now switch to DIVIDEND = B'C'BC / DIVISOR = D'E'DE (A / B)
	        push de ; push Lowpart(Q)
			ex de, hl	; DE = HL
	        ld hl, 0
	        exx
	        ld b, h
	        ld c, l
	        pop hl
	        push de
	        ex de, hl
	        ld hl, 0        ; H'L'HL = 0
	        exx
	        pop bc          ; Pop HightPart(B) => B = B'C'BC
	        exx
	
	        ld a, 32 ; Loop count
	
__DIV32LOOP:
	        sll c  ; B'C'BC << 1 ; Output most left bit to carry
	        rl  b
	        exx
	        rl c
	        rl b
	        exx
	
	        adc hl, hl
	        exx
	        adc hl, hl
	        exx
	
	        sbc hl,de
	        exx
	        sbc hl,de
	        exx
	        jp nc, __DIV32NOADD	; use JP inside a loop for being faster
	
	        add hl, de
	        exx
	        adc hl, de
	        exx
	        dec bc
	
__DIV32NOADD:
	        dec a
	        jp nz, __DIV32LOOP	; use JP inside a loop for being faster
	        ; At this point, quotient is stored in B'C'BC and the reminder in H'L'HL
	
	        push hl
	        exx
	        pop de
	        ex de, hl ; D'E'H'L' = 32 bits modulus
	        push bc
	        exx
	        pop de    ; DE = B'C'
	        ld h, b
	        ld l, c   ; DEHL = quotient D'E'H'L' = Modulus
	
	        ret     ; DEHL = quotient, D'E'H'L' = Modulus
	
	
	
__MODU32:    ; 32 bit modulus for 32bit unsigned division
	             ; DEHL = Dividend, Stack Top = Divisor (DE, HL)
	
	        exx
	        pop hl   ; return address
	        pop de   ; low part
	        ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
	
	        call __DIVU32START	; At return, modulus is at D'E'H'L'
	
__MODU32START:
	
			exx
			push de
			push hl
	
			exx 
			pop hl
			pop de
	
			ret
	
	
__DIVI32:    ; 32 bit signed division
	             ; DEHL = Dividend, Stack Top = Divisor
	             ; A = Dividend, B = Divisor => A / B
	        exx
	        pop hl   ; return address
	        pop de   ; low part
	        ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
	
__DIVI32START:
			exx
			ld a, d	 ; Save sign
			ex af, af'
			bit 7, d ; Negative?
			call nz, __NEG32 ; Negates DEHL
	
			exx		; Now works with H'L'D'E'
			ex af, af'
			xor h
			ex af, af'  ; Stores sign of the result for later
	
			bit 7, h ; Negative?
			ex de, hl ; HLDE = DEHL
			call nz, __NEG32
			ex de, hl 
	
			call __DIVU32START
			ex af, af' ; Recovers sign
			and 128	   ; positive?
			ret z
	
			jp __NEG32 ; Negates DEHL and returns from there
			
			
__MODI32:	; 32bits signed division modulus
			exx
	        pop hl   ; return address
	        pop de   ; low part
	        ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
	
			call __DIVI32START
			jp __MODU32START		
	
#line 61 "divi32c.bas"
#line 1 "swap32.asm"
	; Exchanges current DE HL with the
	; ones in the stack
	
__SWAP32:
		pop bc ; Return address
	
		exx
		pop hl	; exx'
		pop de
	
		exx
		push de ; exx
		push hl
	
		exx		; exx '
		push de
		push hl
		
		exx		; exx
		pop hl
		pop de
	
		push bc
	
		ret
	
#line 62 "divi32c.bas"
	
ZXBASIC_USER_DATA:
_le:
	DEFB 02h
	DEFB 00h
	DEFB 00h
	DEFB 00h
_l:
	DEFB 00, 00, 00, 00
_level:
	DEFB 01h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
