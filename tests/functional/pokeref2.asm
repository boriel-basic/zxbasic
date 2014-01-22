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
__LABEL__printAt42Coords:
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
_printat42:
	push ix
	ld ix, 0
	add ix, sp
	ld a, (ix+7)
	ld (__LABEL__printAt42Coords), a
	ld a, (ix+5)
	ld (__LABEL__printAt42Coords + 1), a
_printat42__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	pop bc
	ex (sp), hl
	exx
	ret
	
ZXBASIC_USER_DATA:
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
