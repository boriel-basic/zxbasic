#include once <u32tofreg.asm>
#include once <ftou32reg.asm>
#include once <stackf.asm>

; -------------------------------------------------------------
; Floating point library using the FP ROM Calculator (ZX 48K)

; All of them uses C EDHL registers as 1st paramter.
; For binary operators, the 2n operator must be pushed into the
; stack, in the order BC DE HL (B not used).
;
; Uses CALLEE convention
; -------------------------------------------------------------

__NOTF:	; A = ¬A 
	call __FPSTACK_PUSH
	
	; ------------- ROM NOT
	rst 28h
	defb 30h	; 
	defb 38h;   ; END CALC

	call __FPSTACK_POP 
	jp __FTOU8 ; Convert to 8 bits

