#include once <stackf.asm>

LN: ; Computes Ln(x) using ROM FP-CALC
	call __FPSTACK_PUSH

	rst 28h	; ROM CALC
	defb 20h ; 25h
	defb 38h ; END CALC

	jp __FPSTACK_POP

