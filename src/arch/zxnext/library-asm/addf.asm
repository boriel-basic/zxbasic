#include once <stackf.asm>

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

