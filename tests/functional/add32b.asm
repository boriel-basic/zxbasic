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
	ld de, (_a + 2)
	ld bc, (_a)
	add hl, bc
	ex de, hl
	ld bc, (_a + 2)
	adc hl, bc
	push hl
	push de
	ld de, 0
	ld hl, 2
	ld bc, (_a)
	add hl, bc
	ex de, hl
	ld bc, (_a + 2)
	adc hl, bc
	ex de, hl
	ld bc, (_a)
	add hl, bc
	ex de, hl
	ld bc, (_a + 2)
	adc hl, bc
	ex de, hl
	pop bc
	add hl, bc
	ex de, hl
	pop bc
	adc hl, bc
	ex de, hl
	ld (_a), hl
	ld (_a + 2), de
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
	DEFB 00, 00, 00, 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
