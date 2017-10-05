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
	call _test
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
	ld hl, -9
	add hl, sp
	ld sp, hl
	ld (hl), 0
	ld bc, 8
	ld d, h
	ld e, l
	inc de
	ldir
	push ix
	pop hl
	ld bc, -9
	add hl, bc
	ex de, hl
	ld hl, __LABEL0
	ld bc, 6
	ldir
__LABEL__label1:
__LABEL__label2:
__LABEL__label3:
	ld l, (ix-6)
	ld h, (ix-5)
	push hl
	ld a, 5
	pop hl
	ld (hl), a
_test__leave:
	ld sp, ix
	pop ix
	ret

ZXBASIC_USER_DATA:
__LABEL0:
	DEFB 00h
	DEFB 00h
	DEFB 02h
	DEFW __LABEL__label1
	DEFW __LABEL__label2
	DEFW __LABEL__label3
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
