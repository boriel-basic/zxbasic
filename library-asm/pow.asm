#include once <stackf.asm>

; -------------------------------------------------------------
; Floating point library using the FP ROM Calculator (ZX 48K)

; All of them uses A EDCB registers as 1st paramter.
; For binary operators, the 2n operator must be pushed into the
; stack, in the order A DE BC.
;
; Uses CALLEE convention
;
; Operands comes swapped:
; 	1 st parameter is the BASE (A ED CB)
;   2 nd parameter (Top of the stack) is Exponent
; -------------------------------------------------------------

__POW:	; Exponentiation
	PROC
	
	call __FPSTACK_PUSH2
	
	; ------------- ROM POW
	rst 28h
	defb 01h  	; Exchange => 1, Base
	defb 06h	; POW
	defb 38h;   ; END CALC

	jp __FPSTACK_POP

	ENDP

