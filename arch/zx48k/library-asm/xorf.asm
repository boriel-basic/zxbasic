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

__XORF:	; A XOR B
	call __FPSTACK_PUSH2

	; A XOR B == A ^ ¬B v ¬A ^ B
	rst 28h
	defb 0C0h   ; STORE 0
	defb 02h   ; DELETE
	defb 31h   ; DUP 
	defb 30h   ; NOT A
	defb 0E0h   ; Recall 0
	defb 08h   ; AND
	defb 01h   ; SWAP
	defb 0E0h   ; Recall 0
	defb 30h   ; NOT B
	defb 08h   ; AND
	defb 07h   ; OR
	defb 38h   ; END CALC

	call __FPSTACK_POP 
	jp __FTOU8 ; Convert to 8 bits

