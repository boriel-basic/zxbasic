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
__LABEL__10:
	ld a, 1
	ld (_i), a
	jp __LABEL0
__LABEL4:
__LABEL__20:
__LABEL5:
	ld a, (_i)
	inc a
	ld (_i), a
__LABEL0:
	ld a, 10
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL4
__LABEL3:
__LABEL__30:
	ld a, 1
	ld (_i), a
	jp __LABEL6
__LABEL10:
__LABEL__40:
__LABEL11:
	ld a, (_i)
	inc a
	ld (_i), a
__LABEL6:
	ld a, 10
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL10
__LABEL9:
	ld a, 1
	ld (_i), a
	jp __LABEL12
__LABEL16:
__LABEL17:
	ld a, (_i)
	inc a
	ld (_i), a
__LABEL12:
	ld a, 10
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL16
__LABEL15:
	ld a, 1
	ld (_i), a
	jp __LABEL18
__LABEL22:
__LABEL23:
	ld a, (_i)
	inc a
	ld (_i), a
__LABEL18:
	ld a, 10
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL22
__LABEL21:
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
	; Defines DATA END --> HEAP size is 0
ZXBASIC_USER_DATA_END EQU ZXBASIC_MEM_HEAP
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	END
