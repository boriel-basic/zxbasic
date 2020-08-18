#include once <stackf.asm>

SQRT: ; Computes SQRT(x) using ROM FP-CALC
	call __FPSTACK_PUSH

	rst 28h	; ROM CALC
	defb 28h ; SQRT
	defb 38h ; END CALC

	jp __FPSTACK_POP

