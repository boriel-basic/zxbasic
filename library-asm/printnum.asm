#include once <print.asm>
#include once <attr.asm>

__PRINTU_START:
	PROC

	LOCAL __PRINTU_CONT

	ld a, b
	or a
	jp nz, __PRINTU_CONT

	ld a, '0'
	jp __PRINT_DIGIT
	

__PRINTU_CONT:
	pop af
	push bc
	call __PRINT_DIGIT
	pop bc
	djnz __PRINTU_CONT
	ret

	ENDP
	

__PRINT_MINUS: ; PRINT the MINUS (-) sign. CALLER mus preserve registers
	ld a, '-'
	jp __PRINT_DIGIT

__PRINT_DIGIT EQU __PRINTCHAR ; PRINTS the char in A register, and puts its attrs

	
