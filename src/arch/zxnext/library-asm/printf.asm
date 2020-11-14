#include once <printstr.asm>
#include once <stackf.asm>
#include once <const.asm>

__PRINTF:	; Prints a Fixed point Number stored in C ED LH
	PROC

	LOCAL RECLAIM2
	LOCAL STK_END
STK_END EQU	5C65h

	ld hl, (ATTR_T)
	push hl ; Saves ATTR_T since BUG ROM changes it

	ld hl, (STK_END)
	push hl	; Stores STK_END

	call __FPSTACK_PUSH ; Push number into stack
	rst 28h		; # Rom Calculator
	defb 2Eh	; # STR$(x)
	defb 38h	; # END CALC
	call __FPSTACK_POP ; Recovers string parameters to A ED CB

	pop hl
	ld (STK_END), hl ; Balance STK_END to avoid STR$ bug

	pop hl
	ld (ATTR_T), hl	 ; Restores ATTR_T

	ex de, hl	; String position now in HL

	push bc
    xor a       ; Avoid the str to be FREED from heap
	call __PRINT_STR
	pop bc 
	inc bc

	jp RECLAIM2 ; Frees TMP Memory

RECLAIM2 EQU 19E8h

	ENDP

