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
	core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU core.ZXBASIC_USER_DATA_LEN
	core.__LABEL__.ZXBASIC_USER_DATA EQU core.ZXBASIC_USER_DATA
_a:
	DEFB 00h
_result:
	DEFB 00, 00
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
	ld hl, 32767
	ld (_result), hl
	ld a, (_a)
	ld b, a
	ld hl, 32767
	or a
	jr z, __LABEL1
__LABEL0:
	srl h
	rr l
	djnz __LABEL0
__LABEL1:
	ld (_result), hl
	ld hl, 32767
	ld (_result), hl
	ld a, (_a)
	ld b, a
	ld hl, 32767
	or a
	jr z, __LABEL3
__LABEL2:
	add hl, hl
	djnz __LABEL2
__LABEL3:
	ld (_result), hl
	ld hl, 65024
	ld (_result), hl
	ld a, (_a)
	ld b, a
	ld hl, 65024
	or a
	jr z, __LABEL5
__LABEL4:
	sra h
	rr l
	djnz __LABEL4
__LABEL5:
	ld (_result), hl
	ld hl, 65024
	ld (_result), hl
	ld a, (_a)
	ld b, a
	ld hl, 65024
	or a
	jr z, __LABEL7
__LABEL6:
	add hl, hl
	djnz __LABEL6
__LABEL7:
	ld (_result), hl
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
