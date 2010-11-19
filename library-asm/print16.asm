#include once <printnum.asm>
#include once <div16.asm>
#include once <neg16.asm>
#include once <attr.asm>

__PRINTI16:	; Prints a 16bits signed in HL
			; Converts 16 to 32 bits
	PROC

	LOCAL __PRINTU_LOOP
	ld a, h
	or a

	jp p, __PRINTU16

	call __PRINT_MINUS
	call __NEGHL

__PRINTU16:

	ld b, 0
__PRINTU_LOOP:
	ld a, h
	or l
	jp z, __PRINTU_START

	push bc
	ld de, 10
	call __DIVU16_FAST ; Divides by DE. DE = MODULUS at exit. Since < 256, E = Modulus
	pop bc

	ld a, e
	or '0'		  ; Stores ASCII digit (must be print in reversed order)
	push af
	inc b
	jp __PRINTU_LOOP ; Uses JP in loops

	ENDP

