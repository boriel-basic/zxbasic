#include once <stackf.asm>

EXP: ; Computes e^n using ROM FP-CALC
	call __FPSTACK_PUSH

	rst 28h	; ROM CALC
	defb 26h ; E^n
	defb 38h ; END CALC

	jp __FPSTACK_POP

