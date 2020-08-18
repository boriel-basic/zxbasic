#include once <stackf.asm>

ASIN: ; Computes ASIN using ROM FP-CALC
	call __FPSTACK_PUSH

	rst 28h	; ROM CALC
	defb 22h ; ASIN
	defb 38h ; END CALC

	jp __FPSTACK_POP

