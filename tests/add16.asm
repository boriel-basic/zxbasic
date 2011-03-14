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
	ld hl, (_a)
	ld (_b), hl
	ld hl, (_a)
	inc hl
	ld (_b), hl
	ld hl, (_a)
	ld (_b), hl
	ld hl, (_a)
	inc hl
	ld (_b), hl
	ld de, (_a)
	ld hl, (_a)
	add hl, de
	ld (_b), hl
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
_a:
	DEFB 00, 00
_b:
	DEFB 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
