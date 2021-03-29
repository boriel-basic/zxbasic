	org 32768
core.__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (core.__CALL_BACK__), hl
	ei
	jp core.__MAIN_PROGRAM__
core.__CALL_BACK__:
	DEFW 0
core.ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
core.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_END - core.ZXBASIC_USER_DATA
	core..__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core..__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
_i:
	DEFB 00
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
__LABEL__10:
	ld a, 1
	ld (_i), a
	jp __LABEL0
__LABEL3:
__LABEL__20:
__LABEL4:
	ld hl, _i
	inc (hl)
__LABEL0:
	ld a, 10
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL3
__LABEL2:
__LABEL__30:
	ld a, 1
	ld (_i), a
	jp __LABEL5
__LABEL8:
__LABEL__40:
__LABEL9:
	ld hl, _i
	inc (hl)
__LABEL5:
	ld a, 10
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL8
__LABEL7:
	ld a, 1
	ld (_i), a
	jp __LABEL10
__LABEL13:
__LABEL14:
	ld hl, _i
	inc (hl)
__LABEL10:
	ld a, 10
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL13
__LABEL12:
	ld a, 1
	ld (_i), a
	jp __LABEL15
__LABEL18:
__LABEL19:
	ld hl, _i
	inc (hl)
__LABEL15:
	ld a, 10
	ld hl, (_i - 1)
	cp h
	jp nc, __LABEL18
__LABEL17:
	ld hl, 0
	ld b, h
	ld c, l
core.__END_PROGRAM:
	di
	ld hl, (core.__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
	END
