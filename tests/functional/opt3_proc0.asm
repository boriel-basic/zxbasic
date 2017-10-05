	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	call _p
	ld bc, 0
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	pop iy
	pop ix
	exx
	ei
	ret
__CALL_BACK__:
	DEFW 0
_p:
	push ix
	ld ix, 0
	add ix, sp
#line 3
		PROC
		CP 22
		JR NZ, isNewline
		LOCAL isAt
isAt:
		EX DE,HL
		LD HL, -2
		ADD HL, BC
		EX DE,HL
		INC HL
		LD D,(HL)
		DEC BC
		INC HL
		LD E,(HL)
		DEC BC
		LOCAL isNewline
isNewline:
		ENDP
#line 21
_p__leave:
	ld sp, ix
	pop ix
	ret

ZXBASIC_USER_DATA:
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
