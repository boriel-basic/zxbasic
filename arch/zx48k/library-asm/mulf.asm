#include once <stackf.asm>

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

