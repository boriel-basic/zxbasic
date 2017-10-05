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
	call __SWAP32
	call __MODF16
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le + 2)
	push hl
	ld hl, (_le)
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __MODF16
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __MODF16
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_le)
	ld de, (_le + 2)
	push de
	push hl
	ld hl, (_level)
	ld de, (_level + 2)
	call __MODF16
	ld (_l), hl
	ld (_l + 2), de
	ld hl, (_level)
	ld de, (_level + 2)
	ld bc, 2
	push bc
	ld bc, 0
	push bc
	call __MODF16
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
#line 1 "modf16.asm"

	; Computes A % B for fixed values

#line 1 "divf16.asm"

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

#line 2 "divf16.asm"


__DIVF16:	; 16.16 Fixed point Division (signed)

	            ; DE.HL = Dividend, Stack Top = Divisor
	            ; A = Dividend, B = Divisor => A / B
	                exx
	                pop hl   ; return address
	                pop de   ; low part
	                ex (sp), hl ; CALLEE Convention ; H'L'D'E' => Dividend
					ex de, hl   ; D'E'.H'L' Dividend

__DIVF16START: ; FAST Entry: DEHL => Dividend, D'E'H'L' => Divisor
			ld a, d	 ; Save sign
			ex af, af'
			bit 7, d ; Negative?
			call nz, __NEG32 ; Negates DEHL

			exx		; Now works with D'E'.H'L'
			ex af, af'
			xor d
			ex af, af'  ; Stores sign of the result for later

			bit 7, d ; Negative?
			call nz, __NEG32
			exx		 ; Now we have DE.HL => Dividend

			ld b, 16

__SHIFTALOOP:		; Tries to shift Dividend to the left
	        bit 7, d
			jp nz, __SHIFTB
	        add hl, hl
			ex de, hl
	        adc hl, hl
			ex de, hl
	        djnz __SHIFTALOOP
	        jp __DOF16_DIVRDY

__SHIFTB:       ; Cannot shift Dividend more to the left, try to shift Divisor to the right
	        ld a, b
	        exx
	        ld b, a
	                ; Divisor is in DEHL
__SHIFTBLOOP:
	        bit 1, l
			jp nz, __DOF16_DIVIDE
	        sra d
	        rr e
	        rr h
	        rr l
	        djnz __SHIFTBLOOP

__DOF16_DIVIDE:
	        ld a, b
	        exx
	        ld b, a

__DOF16_DIVRDY:
			exx
			ex de, hl
	        push bc
			call __DIVU32START
			pop bc

			xor a
			or b
			jp z, __ENDF16DIV

__SHIFTCLOOP:
			add hl, hl	; Shift DECIMAL PART << 1
			ex de, hl
			adc hl, hl  ; Shift INTEGER PART << 1 Plus Carry
			ex de, hl
			djnz __SHIFTCLOOP

__ENDF16DIV: 	   ; Put the sign on the result
			ex af, af' ; Recovers sign
			and 128	   ; positive?
			ret z
			jp __NEG32 ; Negates DEHL and returns from there

#line 4 "modf16.asm"
#line 1 "mulf16.asm"


#line 1 "_mul32.asm"


; Ripped from: http://www.andreadrian.de/oldcpu/z80_number_cruncher.html#moztocid784223
	; Used with permission.
	; Multiplies 32x32 bit integer (DEHL x D'E'H'L')
	; 64bit result is returned in H'L'H L B'C'A C


__MUL32_64START:
			push hl
			exx
			ld b, h
			ld c, l		; BC = Low Part (A)
			pop hl		; HL = Load Part (B)
			ex de, hl	; DE = Low Part (B), HL = HightPart(A) (must be in B'C')
			push hl

			exx
			pop bc		; B'C' = HightPart(A)
			exx			; A = B'C'BC , B = D'E'DE

				; multiply routine 32 * 32bit = 64bit
				; h'l'hlb'c'ac = b'c'bc * d'e'de
				; needs register a, changes flags
				;
				; this routine was with tiny differences in the
				; sinclair zx81 rom for the mantissa multiply

__LMUL:
	        and     a               ; reset carry flag
	        sbc     hl,hl           ; result bits 32..47 = 0
	        exx
	        sbc     hl,hl           ; result bits 48..63 = 0
	        exx
	        ld      a,b             ; mpr is b'c'ac
	        ld      b,33            ; initialize loop counter
	        jp      __LMULSTART

__LMULLOOP:
	        jr      nc,__LMULNOADD  ; JP is 2 cycles faster than JR. Since it's inside a LOOP
	                                ; it can save up to 33 * 2 = 66 cycles
	                                ; But JR if 3 cycles faster if JUMP not taken!
	        add     hl,de           ; result += mpd
	        exx
	        adc     hl,de
	        exx

__LMULNOADD:
	        exx
	        rr      h               ; right shift upper
	        rr      l               ; 32bit of result
	        exx
	        rr      h
	        rr      l

__LMULSTART:
	        exx
	        rr      b               ; right shift mpr/
	        rr      c               ; lower 32bit of result
	        exx
	        rra                     ; equivalent to rr a
	        rr      c
	        djnz    __LMULLOOP

			ret						; result in h'l'hlb'c'ac

#line 3 "mulf16.asm"

__MULF16:		;
	        ld      a, d            ; load sgn into a
	        ex      af, af'         ; saves it
	        call    __ABS32         ; convert to positive

			exx
			pop hl ; Return address
			pop de ; Low part
			ex (sp), hl ; CALLEE caller convention; Now HL = Hight part, (SP) = Return address
			ex de, hl	; D'E' = High part (B),  H'L' = Low part (B) (must be in DE)

	        ex      af, af'
	        xor     d               ; A register contains resulting sgn
	        ex      af, af'
	        call    __ABS32         ; convert to positive

			call __MUL32_64START

	; rounding (was not included in zx81)
__ROUND_FIX:					; rounds a 64bit (32.32) fixed point number to 16.16
									; result returned in dehl
									; input in h'l'hlb'c'ac
	        sla     a               ; result bit 47 to carry
	        exx
	        ld      hl,0            ; ld does not change carry
	        adc     hl,bc           ; hl = hl + 0 + carry
			push	hl

	        exx
	        ld      bc,0
	        adc     hl,bc           ; hl = hl + 0 + carry
			ex		de, hl
			pop		hl              ; rounded result in de.hl

	        ex      af, af'         ; recovers result sign
	        or      a
	        jp      m, __NEG32      ; if negative, negates it

			ret

#line 5 "modf16.asm"

__MODF16:
	            ; 16.16 Fixed point Division (signed)
	            ; DE.HL = Divisor, Stack Top = Divider
	            ; A = Dividend, B = Divisor => A % B

	PROC
	    LOCAL TEMP

	TEMP EQU 23698       ; MEMBOT

	    pop bc              ; ret addr
	    ld (TEMP), bc       ; stores it on MEMBOT temporarily
		ld (TEMP + 2), hl   ; stores HP of divider
		ld (TEMP + 4), de   ; stores DE of divider

	    call __DIVF16
		rlc d				; Sign into carry
		sbc a, a			; a register = -1 sgn(DE), or 0
		ld d, a
		ld e, a				; DE = 0 if it was positive or 0; -1 if it was negative

		ld bc, (TEMP + 4)	; Pushes original divider into the stack
		push bc
		ld bc, (TEMP + 2)
		push bc

	    ld bc, (TEMP)    ; recovers return address
	    push bc
	    jp __MULF16			; multiplies and return from there

	ENDP

#line 68 "modf16c.bas"
#line 1 "swap32.asm"

	; Exchanges current DE HL with the
	; ones in the stack

__SWAP32:
		pop bc ; Return address
	    ex (sp), hl
	    dec sp
	    dec sp
	    ex de, hl
	    ex (sp), hl
	    ex de, hl
	    inc sp
	    inc sp
	    push bc
		ret

#line 69 "modf16c.bas"

ZXBASIC_USER_DATA:
_level:
	DEFB 00h
	DEFB 00h
	DEFB 01h
	DEFB 00h
_le:
	DEFB 00h
	DEFB 00h
	DEFB 02h
	DEFB 00h
_l:
	DEFB 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
