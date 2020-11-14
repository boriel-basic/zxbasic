#include once <neg32.asm>

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

