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
	ld a, (_num)
	dec a
	jp nz, __LABEL0
	ld a, 2
	ld (_num), a
	jp __LABEL1
__LABEL0:
	ld a, (_num)
	sub 2
	jp nz, __LABEL2
	ld a, 3
	ld (_num), a
	jp __LABEL3
__LABEL2:
	ld a, 4
	ld (_num), a
__LABEL3:
__LABEL1:
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
_num:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
