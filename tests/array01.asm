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
	ld a, 5
	ld (_a + 4), a
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
__CALL_BACK__:
	DEFW 0
	
ZXBASIC_USER_DATA:
_b:
	DEFB 00
_a:
	DEFW 0000h
	DEFB 01h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	DEFB 00h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
