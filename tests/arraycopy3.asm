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
_Test:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, -16
	add hl, sp
	ld sp, hl
	ld (hl), 0
	ld bc, 15
	ld d, h
	ld e, l
	inc de
	ldir
	push ix
	pop hl
	ld bc, -8
	add hl, bc
	ex de, hl
	ld hl, __LABEL0
	ld bc, 8
	ldir
	push ix
	pop hl
	ld bc, -16
	add hl, bc
	ex de, hl
	ld hl, __LABEL1
	ld bc, 3
	ldir
	push ix
	pop hl
	ld de, -13
	add hl, de
	push hl
	push ix
	pop hl
	ld de, -5
	add hl, de
	push hl
	ld hl, 5
	ld b, h
	ld c, l
	pop hl
	pop de
	ldir
_Test__leave:
	ld sp, ix
	pop ix
	ret
	
ZXBASIC_USER_DATA:
__LABEL0:
	DEFB 00h
	DEFB 00h
	DEFB 01h
	DEFB 00h
	DEFB 01h
	DEFB 02h
	DEFB 03h
	DEFB 04h
__LABEL1:
	DEFB 00h
	DEFB 00h
	DEFB 01h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
