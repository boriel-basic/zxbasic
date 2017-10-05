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
	ld a, 1
	ld (_Map), a
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
_q:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	push hl
	push ix
	pop hl
	ld bc, -2
	add hl, bc
	ex de, hl
	ld hl, __LABEL0
	ld bc, 2
	ldir
	ld a, 2
	ld (_Map), a
_q__leave:
	ld sp, ix
	pop ix
	ret

ZXBASIC_USER_DATA:
_Map:
	DEFB 00
__LABEL0:
	DEFW _Map
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
