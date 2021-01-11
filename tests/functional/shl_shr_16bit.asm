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
	jp __MAIN_PROGRAM__
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_a:
	DEFB 00h
_result:
	DEFB 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
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
	;; --- end of user code ---
	END
