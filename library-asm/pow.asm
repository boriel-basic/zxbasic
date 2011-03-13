#include once <stackf.asm>

; -------------------------------------------------------------
; Floating point library using the FP ROM Calculator (ZX 48K)

; All of them uses A EDCB registers as 1st paramter.
; For binary operators, the 2n operator must be pushed into the
; stack, in the order A DE BC.
;
; Uses CALLEE convention
;
; Since the ROM uses LN to calculate this, exponents must be
; positive (Try 2^-1 in your speccy)
; We can fix this by checking in advance if exponent is < 0
; and returning 1 / (B ^ abs(e))
;
; Operands comes swapped:
; 	1 st parameter is the BASE (A ED CB)
;   2 nd parameter (Top of the stack) is Exponent
; -------------------------------------------------------------

__POW:	; Exponentiation
	PROC
	
	LOCAL __POSITIVE

	bit 7, e
	jr z, __POSITIVE
	res 7, e ; Make exponent positive

	push bc  ; Preserve exponent
	push de
	push af

	rst 28h
	defb 0A1h ; Push 1	 => Base, 1
	defb 38h ; END CALC

	pop af	 ; Recover current number
	pop de
	pop bc

	call __FPSTACK_PUSH2
	
	; ------------- ROM POW
	rst 28h
	defb 01h  	; Exchange => 1, Base
	defb 06h	; POW
	defb 05h	; DIV
	defb 38h;   ; END CALC
	
	jp __FPSTACK_POP


__POSITIVE:	; Proceed as always
	call __FPSTACK_PUSH2
	
	; ------------- ROM POW
	rst 28h
	defb 01h  	; Exchange => 1, Base
	defb 06h	; POW
	defb 38h;   ; END CALC

	jp __FPSTACK_POP

	ENDP

