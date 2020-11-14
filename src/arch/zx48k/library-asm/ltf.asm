#include once <u32tofreg.asm>
#include once <ftou32reg.asm>
#include once <stackf.asm>

; -------------------------------------------------------------
; Floating point library using the FP ROM Calculator (ZX 48K)

; All of them uses A EDCB registers as 1st paramter.
; For binary operators, the 2n operator must be pushed into the
; stack, in the order A HL BC.
;
; Uses CALLEE convention
; -------------------------------------------------------------

__LTF:	; A < B
	call __FPSTACK_PUSH2 ; Enters B, A
	
	; ------------- ROM NOS-LESS
	ld b, 0Ch	; A > B (Operands stack-reversed)
	rst 28h
	defb 0Ch;	; A > B
	defb 38h;   ; END CALC

	call __FPSTACK_POP 
	jp __FTOU8 ; Convert to 8 bits

