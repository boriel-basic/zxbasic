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
_test:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, -18
	add hl, sp
	ld sp, hl
	ld (hl), 0
	ld bc, 17
	ld d, h
	ld e, l
	inc de
	ldir
	push ix
	pop hl
	ld bc, -18
	add hl, bc
	ex de, hl
	ld hl, __LABEL0
	ld bc, 17
	ldir
	ld a, (ix-6)
	ld (ix-1), a
_test__leave:
	ld sp, ix
	pop ix
	ret
	
ZXBASIC_USER_DATA:
__LABEL0:
	DEFB 01h
	DEFB 00h
	DEFB 04h
	DEFB 00h
	DEFB 01h
	DEFB 0A0h
	DEFB 0A1h
	DEFB 0A2h
	DEFB 0A3h
	DEFB 0B0h
	DEFB 0B1h
	DEFB 0B2h
	DEFB 0B3h
	DEFB 0C0h
	DEFB 0C1h
	DEFB 0C2h
	DEFB 0C3h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
