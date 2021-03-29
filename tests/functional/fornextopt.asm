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
_a:
	DEFB 00
core.ZXBASIC_USER_DATA_END:
core.__MAIN_PROGRAM__:
	ld a, 1
	ld (_a), a
	jp __LABEL0
__LABEL3:
__LABEL__lbl:
	ld hl, _a
	inc (hl)
__LABEL4:
	ld hl, _a
	inc (hl)
__LABEL0:
	xor a
	ld hl, (_a - 1)
	cp h
	jp nc, __LABEL3
__LABEL2:
	jp __LABEL__lbl
	;; --- end of user code ---
	END
