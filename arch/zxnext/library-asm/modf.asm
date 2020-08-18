#include once <stackf.asm>

; -------------------------------------------------------------
; Floating point library using the FP ROM Calculator (ZX 48K)

; All of them uses A EDCB registers as 1st paramter.
; For binary operators, the 2n operator must be pushed into the
; stack, in the order A DE BC.
;
; Uses CALLEE convention
; -------------------------------------------------------------

__MODF:	; MODULO
	call __FPSTACK_PUSH2	; Enters B, A
	
	; ------------- ROM DIV
	rst 28h
	defb 01h	; EXCHANGE
	defb 32h	; MOD
	defb 38h;   ; END CALC

	jp __FPSTACK_POP

