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
__LABEL__30:
	ld a, 1
	ld (_i), a
	jp __LABEL0
__LABEL3:
	ld a, 1
	ld (_m), a
	jp __LABEL5
__LABEL8:
__LABEL__40:
	xor a
	ld (_M), a
__LABEL9:
	ld a, (_m)
	inc a
	ld (_m), a
__LABEL5:
	ld a, 6
	ld hl, (_m - 1)
	cp h
	jp nc, __LABEL8
__LABEL7:
__LABEL4:
	ld a, (_i)
	inc a
	ld (_i), a
__LABEL0:
	ld a, 8
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL3
__LABEL2:
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
_i:
	DEFB 00
_m:
	DEFB 00
_M:
	DEFB 00
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
