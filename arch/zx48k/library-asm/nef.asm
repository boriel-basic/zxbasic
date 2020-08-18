#include once <u32tofreg.asm>
#include once <ftou32reg.asm>
#include once <stackf.asm>

; -------------------------------------------------------------
; Floating point library using the FP ROM Calculator (ZX 48K)

; All of them uses A EDCB registers as 1st paramter.
; For binary operators, the 2n operator must be pushed into the
; stack, in the order A DE BC.
;
; Uses CALLEE convention
; -------------------------------------------------------------

__NEF:	; A <> B
	call __FPSTACK_PUSH2	; Enters B, A
	
	; ------------- ROM NOS-NEQ
	ld b, 0Bh
	rst 28h
	defb 0Bh
	defb 38h    ; END CALC

	call __FPSTACK_POP 
	jp __FTOU8 ; Convert to 8 bits

