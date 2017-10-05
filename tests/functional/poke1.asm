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
	ld hl, 0
	push hl
	push hl
	inc sp
	push ix
	pop hl
	ld bc, -3
	add hl, bc
	ex de, hl
	ld hl, __LABEL5
	ld bc, 2
	ldir
	ld (ix-1), 0
	jp __LABEL0
__LABEL3:
	ld l, (ix-3)
	ld h, (ix-2)
	push hl
	ld hl, 65535
	ex de, hl
	pop hl
	ld (hl), e
	inc hl
	ld (hl), d
	ld l, (ix-3)
	ld h, (ix-2)
	inc hl
	ld (ix-3), l
	ld (ix-2), h
__LABEL4:
	ld a, (ix-1)
	inc a
	ld (ix-1), a
__LABEL0:
	ld a, (ix-1)
	push af
	ld a, 250
	pop hl
	cp h
	jp nc, __LABEL3
__LABEL2:
_test__leave:
	ld sp, ix
	pop ix
	ret

ZXBASIC_USER_DATA:
__LABEL5:
	DEFB 00h
	DEFB 40h
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
