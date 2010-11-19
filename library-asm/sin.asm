#include once <stackf.asm>

SIN: ; Computes SIN using ROM FP-CALC
	call __FPSTACK_PUSH

	rst 28h	; ROM CALC
	defb 1Fh
	defb 38h ; END CALC

	jp __FPSTACK_POP

