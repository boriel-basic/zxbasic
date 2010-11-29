#include once <printnum.asm>
#include once <div8.asm>

__PRINTI8:	; Prints an 8 bits number in Accumulator (A)
			; Converts 8 to 32 bits
	or a
	jp p, __PRINTU8

	push af
	call __PRINT_MINUS
	pop af
	neg

__PRINTU8:
	PROC

	LOCAL __PRINTU_LOOP

	ld b, 0 ; Counter

__PRINTU_LOOP:
	or a
	jp z, __PRINTU_START

	push bc
	ld h, 10
	call __DIVU8_FAST ; Divides by 10. D'E'H'L' contains modulo (L' since < 10)
	pop bc

	ld a, l
	or '0'		  ; Stores ASCII digit (must be print in reversed order)
	push af
	ld a, h
	inc b
	jp __PRINTU_LOOP ; Uses JP in loops

	ENDP

