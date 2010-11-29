#include once <printnum.asm>
#include once <neg32.asm>
#include once <div32.asm>
#include once <attr.asm>


__PRINTI32:
	ld a, d
	or a
	jp p, __PRINTU32

	call __PRINT_MINUS
	call __NEG32

__PRINTU32:
	PROC
	LOCAL __PRINTU_LOOP

	ld b, 0 ; Counter

__PRINTU_LOOP:
	ld a, h
	or l
	or d
	or e
	jp z, __PRINTU_START

	push bc

	ld bc, 0
	push bc
	ld bc, 10
	push bc		  ; Push 00 0A (10 Dec) into the stack = divisor

	call __DIVU32 ; Divides by 32. D'E'H'L' contains modulo (L' since < 10)
	pop bc

	exx
	ld a, l
	or '0'		  ; Stores ASCII digit (must be print in reversed order)
	push af
	exx
	inc b
	jp __PRINTU_LOOP ; Uses JP in loops

	ENDP

